const User = require("../models/userSchema");
const Cours = require("../models/coursSchema");
const Presence = require("../models/presenceSchema");
const Note = require("../models/noteSchema");
const Examen = require("../models/examenSchema");
const Classe = require("../models/classeSchema");
const Announcement = require("../models/announcementSchema");
const Seance = require("../models/seanceSchema");
const NodeCache = require("node-cache");
const jwt = require("jsonwebtoken");

// Cache de 5 minutes.
// Chaque rôle et chaque utilisateur disposent de leur propre clé.
const cache = new NodeCache({ stdTTL: 300 });

const CLASS_COLORS = [
  "#3b82f6",
  "#8b5cf6",
  "#ec4899",
  "#14b8a6",
  "#f59e0b",
  "#22c55e",
  "#ef4444",
  "#06b6d4",
];

/* ===========================================================
   GET DASHBOARD STATS
   GET /api/dashboard/stats?range=week
=========================================================== */
exports.getDashboardStats = async (req, res) => {
  try {
    /*
     * Le middleware requireAuthUser doit normalement remplir req.user.
     * Cette fonction ajoute néanmoins un fallback sécurisé qui récupère
     * l'utilisateur depuis le JWT si req.user est absent.
     */
    const authenticatedUser = await resolveAuthenticatedUser(req);

    if (!authenticatedUser) {
      return res.status(401).json({
        message:
          "Utilisateur non authentifié. Aucun utilisateur ou token valide n'a été trouvé.",
      });
    }

    const userId = getUserId(authenticatedUser);
    const role = normalizeUserRole(authenticatedUser.role);
    const range = normalizeRange(req.query?.range);

    if (!userId) {
      return res.status(401).json({
        message: "Identifiant utilisateur manquant.",
      });
    }

    if (!role) {
      return res.status(403).json({
        message: `Rôle utilisateur manquant ou invalide : ${
          authenticatedUser.role || "non défini"
        }`,
      });
    }

    console.log("[dashboard] authenticated user", {
      userId: String(userId),
      originalRole: authenticatedUser.role,
      normalizedRole: role,
      range,
    });

    switch (role) {
      case "admin":
        return await getAdminDashboard(req, res, { userId, range });

      case "enseignant":
        return await getTeacherDashboard(req, res, { userId, range });

      case "etudiant":
        return await getStudentDashboard(req, res, { userId, range });

      default:
        return res.status(403).json({
          message: `Rôle non autorisé pour accéder au dashboard : ${role}`,
        });
    }
  } catch (error) {
    console.error("❌ Erreur getDashboardStats:", error);

    if (error.name === "TokenExpiredError") {
      return res.status(401).json({
        message: "Session expirée. Veuillez vous reconnecter.",
      });
    }

    if (error.name === "JsonWebTokenError") {
      return res.status(401).json({
        message: "Token d'authentification invalide.",
      });
    }

    return res.status(500).json({
      message: error.message || "Erreur serveur",
      error: error.message,
      errorName: error.name,
    });
  }
};

/* ===========================================================
   ADMIN DASHBOARD
=========================================================== */
async function getAdminDashboard(req, res, { range }) {
  const cacheKey = `dashboard_admin_${range}`;
  const cachedData = cache.get(cacheKey);

  if (cachedData) {
    return res.status(200).json(cachedData);
  }

  const [
    userStats,
    activeCourses,
    totalClasses,
    attendanceDocuments,
    classes,
    announcements,
    recentUsers,
  ] = await Promise.all([
    User.aggregate([
      {
        $addFields: {
          normalizedRole: {
            $switch: {
              branches: [
                {
                  case: { $in: ["$role", ["etudiant", "student"]] },
                  then: "etudiant",
                },
                {
                  case: {
                    $in: [
                      "$role",
                      ["enseignant", "teacher", "prof", "professeur"],
                    ],
                  },
                  then: "enseignant",
                },
                {
                  case: { $in: ["$role", ["admin", "administrator"]] },
                  then: "admin",
                },
              ],
              default: "$role",
            },
          },
        },
      },
      {
        $group: {
          _id: "$normalizedRole",
          count: { $sum: 1 },
          maleCount: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ["$normalizedRole", "etudiant"] },
                    { $eq: ["$sexe", "Homme"] },
                  ],
                },
                1,
                0,
              ],
            },
          },
          femaleCount: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ["$normalizedRole", "etudiant"] },
                    { $eq: ["$sexe", "Femme"] },
                  ],
                },
                1,
                0,
              ],
            },
          },
        },
      },
    ]),
    Cours.countDocuments(),
    Classe.countDocuments(),
    Presence.find({}).lean(),
    Classe.find({}, "nom").sort({ nom: 1 }).limit(10).lean(),
    getRecentAnnouncements(),
    User.find({})
      .select("prenom nom role createdAt")
      .sort({ createdAt: -1 })
      .limit(5)
      .lean(),
  ]);

  const studentStat = userStats.find((item) => item._id === "etudiant");
  const teacherStat = userStats.find((item) => item._id === "enseignant");
  const adminStat = userStats.find((item) => item._id === "admin");

  const totalStudents = studentStat?.count || 0;
  const totalTeachers = teacherStat?.count || 0;
  const totalAdmins = adminStat?.count || 0;
  const maleStudents = studentStat?.maleCount || 0;
  const femaleStudents = studentStat?.femaleCount || 0;

  const attendanceRate = calculateAttendanceRate(attendanceDocuments);
  const genderData = calculateGenderData(maleStudents, femaleStudents);

  const {
    classPerformanceData,
    classAttendanceData,
  } = await buildClassMetrics(classes);

  const stats = [
    {
      title: "Total Students",
      value: totalStudents.toLocaleString(),
      icon: "👥",
      change: "",
      color: "from-blue-500 to-cyan-400",
    },
    {
      title: "Total Teachers",
      value: totalTeachers.toLocaleString(),
      icon: "👨‍🏫",
      change: "",
      color: "from-purple-500 to-pink-400",
    },
    {
      title: "Active Courses",
      value: activeCourses.toLocaleString(),
      icon: "📚",
      change: "",
      color: "from-pink-500 to-blue-500",
    },
    {
      title: "Attendance Rate",
      value: `${attendanceRate}%`,
      icon: "📈",
      change: "",
      color: "from-cyan-400 to-purple-500",
    },
  ];

  const recentActivity = recentUsers.map((user) => ({
    action: getUserActivityLabel(user.role),
    user: getFullName(user),
    time: getTimeAgo(user.createdAt),
    icon: getRoleIcon(user.role),
    color: getRoleColor(user.role),
  }));

  const responseData = {
    dashboardType: "admin",
    range,
    summary: {
      totalStudents,
      totalTeachers,
      totalAdmins,
      totalClasses,
      activeCourses,
      attendanceRate,
    },
    stats,
    enrollmentData: [
      {
        category: "Students",
        count: totalStudents,
      },
      {
        category: "Teachers",
        count: totalTeachers,
      },
    ],
    genderData,
    classPerformanceData,
    classAttendanceData,
    announcements,
    recentActivity,
    todaysSessions: [],
  };

  cache.set(cacheKey, responseData);

  return res.status(200).json(responseData);
}

/* ===========================================================
   TEACHER DASHBOARD
=========================================================== */
async function getTeacherDashboard(req, res, { userId, range }) {
  const todayKey = new Date().toISOString().slice(0, 10);
  const cacheKey = `dashboard_teacher_${userId}_${range}_${todayKey}`;
  const cachedData = cache.get(cacheKey);

  if (cachedData) {
    return res.status(200).json(cachedData);
  }

  const teacher = await User.findById(userId)
    .select("prenom nom email role")
    .lean();

  if (!teacher) {
    return res.status(404).json({
      message: "Enseignant introuvable.",
    });
  }

  const teacherSessions = await Seance.find({
    enseignant: userId,
    statut: "actif",
  })
    .populate({
      path: "cours",
      select: "nom titre",
    })
    .populate({
      path: "classe",
      select: "nom",
    })
    .sort({ jourSemaine: 1, heureDebut: 1 })
    .lean();

  const courseIds = uniqueIds(
    teacherSessions.map((session) => session.cours?._id || session.cours)
  );

  const classIds = uniqueIds(
    teacherSessions.map((session) => session.classe?._id || session.classe)
  );

  const classDocuments = teacherSessions
    .map((session) => session.classe)
    .filter((classe) => classe && typeof classe === "object");

  const uniqueClasses = deduplicateDocuments(classDocuments);

  const students = classIds.length
    ? await User.find({
        role: { $in: ["etudiant", "student"] },
        classe: { $in: classIds },
      })
        .select("prenom nom classe")
        .lean()
    : [];

  const studentIds = students.map((student) => student._id);

  const [teacherNotes, teacherPresences, announcements] = await Promise.all([
    findNotesForTeacher(userId, courseIds, studentIds),
    findPresencesForTeacher(userId, teacherSessions, studentIds),
    getRecentAnnouncements(),
  ]);

  const todaysSessions = filterTodaySessions(teacherSessions).map(
    mapTeacherSession
  );

  const attendanceRate = calculateAttendanceRate(teacherPresences);
  const averageGrade = calculateAverageGrade(teacherNotes);

  const {
    classPerformanceData,
    classAttendanceData,
  } = await buildClassMetrics(uniqueClasses);

  const recentNotes = teacherNotes
    .sort(sortByNewest)
    .slice(0, 5)
    .map((note) => ({
      _id: note._id,
      studentId: objectIdToString(
        note.etudiant || note.student || note.user
      ),
      value: extractGradeValue(note),
      percentage: extractGradePercentage(note),
      date: note.updatedAt || note.createdAt || null,
    }));

  const stats = [
    {
      title: "My Courses",
      value: courseIds.length.toString(),
      icon: "📚",
      change: "",
      color: "from-blue-500 to-cyan-400",
    },
    {
      title: "My Classes",
      value: classIds.length.toString(),
      icon: "🏫",
      change: "",
      color: "from-purple-500 to-pink-400",
    },
    {
      title: "My Students",
      value: students.length.toString(),
      icon: "👥",
      change: "",
      color: "from-pink-500 to-blue-500",
    },
    {
      title: "Attendance Rate",
      value: `${attendanceRate}%`,
      icon: "📈",
      change: "",
      color: "from-cyan-400 to-purple-500",
    },
  ];

  const responseData = {
    dashboardType: "enseignant",
    range,
    teacher: {
      _id: teacher._id,
      fullName: getFullName(teacher),
      email: teacher.email || "",
    },
    summary: {
      totalCourses: courseIds.length,
      totalClasses: classIds.length,
      totalStudents: students.length,
      attendanceRate,
      averageGrade,
      notesCount: teacherNotes.length,
      todaysSessionsCount: todaysSessions.length,
    },
    stats,
    todaysSessions,
    courses: buildTeacherCourses(teacherSessions),
    classes: uniqueClasses.map((classe) => ({
      _id: classe._id,
      name: classe.nom || "",
    })),
    classPerformanceData,
    classAttendanceData,
    recentNotes,
    announcements,
    recentActivity: buildTeacherRecentActivity(
      teacherNotes,
      teacherPresences
    ),
    enrollmentData: [],
    genderData: {
      male: 0,
      female: 0,
      maleCount: 0,
      femaleCount: 0,
    },
  };

  cache.set(cacheKey, responseData);

  return res.status(200).json(responseData);
}

/* ===========================================================
   STUDENT DASHBOARD
=========================================================== */
async function getStudentDashboard(req, res, { userId, range }) {
  const todayKey = new Date().toISOString().slice(0, 10);
  const cacheKey = `dashboard_student_${userId}_${range}_${todayKey}`;
  const cachedData = cache.get(cacheKey);

  if (cachedData) {
    return res.status(200).json(cachedData);
  }

  const student = await User.findById(userId)
    .select("prenom nom email role sexe classe")
    .populate({
      path: "classe",
      select: "nom",
    })
    .lean();

  if (!student) {
    return res.status(404).json({
      message: "Étudiant introuvable.",
    });
  }

  const classeId = student.classe?._id || student.classe || null;

  const [studentSessions, studentNotes, studentPresences, announcements] =
    await Promise.all([
      classeId
        ? Seance.find({
            classe: classeId,
            statut: "actif",
          })
            .populate({
              path: "cours",
              select: "nom titre",
            })
            .populate({
              path: "enseignant",
              select: "prenom nom",
            })
            .sort({ jourSemaine: 1, heureDebut: 1 })
            .lean()
        : [],
      findDocumentsForStudent(Note, userId),
      findDocumentsForStudent(Presence, userId),
      getRecentAnnouncements(),
    ]);

  const todaysSessions = filterTodaySessions(studentSessions).map(
    mapStudentSession
  );

  const courseIds = uniqueIds(
    studentSessions.map((session) => session.cours?._id || session.cours)
  );

  /*
   * Les notes contiennent généralement seulement l'identifiant de l'examen.
   * On récupère donc les examens séparément pour retourner leur titre,
   * leur type, leur date, leur cours et leur barème au frontend.
   */
  const examIds = uniqueIds(
    studentNotes.map((note) => note.examen || note.exam)
  );

  const exams = examIds.length
    ? await Examen.find({
        _id: { $in: examIds },
      })
        // Champs réels de ton examenSchema :
        // nom, type, date, noteMax et coursId
        .select(
          "nom titre type date dateExamen noteMax noteTotale coursId cours"
        )
        .populate({
          path: "coursId",
          select: "nom titre",
        })
        .lean()
    : [];

  const examMap = new Map(
    exams.map((exam) => [objectIdToString(exam._id), exam])
  );

  const attendanceRate = calculateAttendanceRate(studentPresences);
  const averageGrade = calculateAverageGrade(studentNotes, examMap);
  const absenceCount = studentPresences.filter(isAbsentPresence).length;

  const recentNotes = studentNotes
    .sort(sortByNewest)
    .slice(0, 5)
    .map((note) => {
      const examId = objectIdToString(note.examen || note.exam);
      const exam = examMap.get(examId) || null;
      const value = extractGradeValue(note);
      const maxGrade = extractMaxGrade(note, exam);

      return {
        _id: note._id,
        value,
        maxGrade,
        percentage: extractGradePercentage(note, exam),
        date:
          note.updatedAt ||
          note.createdAt ||
          exam?.dateExamen ||
          exam?.date ||
          null,
        examId,
        examName:
          getExamName(exam) ||
          note.examName ||
          note.examenNom ||
          "Exam",
        examType: exam?.type || note.type || "",
        examDate: exam?.dateExamen || exam?.date || null,
        courseId: objectIdToString(
          exam?.coursId?._id ||
          exam?.coursId ||
          exam?.cours?._id ||
          exam?.cours ||
          note.coursId ||
          note.cours ||
          note.course
        ),
        courseName:
          getCourseName(exam?.coursId) ||
          getCourseName(exam?.cours) ||
          getCourseName(note.coursId || note.cours || note.course) ||
          "",
      };
    });

  const stats = [
    {
      title: "My Courses",
      value: courseIds.length.toString(),
      icon: "📚",
      change: "",
      color: "from-blue-500 to-cyan-400",
    },
    {
      title: "Average Grade",
      value: `${averageGrade}%`,
      icon: "🎓",
      change: "",
      color: "from-purple-500 to-pink-400",
    },
    {
      title: "Attendance Rate",
      value: `${attendanceRate}%`,
      icon: "✅",
      change: "",
      color: "from-pink-500 to-blue-500",
    },
    {
      title: "Absences",
      value: absenceCount.toString(),
      icon: "⚠️",
      change: "",
      color: "from-cyan-400 to-purple-500",
    },
  ];

  const responseData = {
    dashboardType: "etudiant",
    range,
    student: {
      _id: student._id,
      fullName: getFullName(student),
      email: student.email || "",
      class: student.classe?.nom || "",
      classId: classeId,
    },
    summary: {
      totalCourses: courseIds.length,
      averageGrade,
      attendanceRate,
      absenceCount,
      notesCount: studentNotes.length,
      todaysSessionsCount: todaysSessions.length,
    },
    stats,
    todaysSessions,
    weeklySchedule: studentSessions.map(mapStudentSession),
    recentNotes,
    attendance: {
      total: studentPresences.length,
      present: studentPresences.filter(isPresentPresence).length,
      absent: absenceCount,
      rate: attendanceRate,
    },
    announcements,
    recentActivity: buildStudentRecentActivity(
      studentNotes,
      studentPresences
    ),
    enrollmentData: [],
    genderData: {
      male: 0,
      female: 0,
      maleCount: 0,
      femaleCount: 0,
    },
    classPerformanceData: [],
    classAttendanceData: [],
  };

  cache.set(cacheKey, responseData);

  return res.status(200).json(responseData);
}

/* ===========================================================
   CLASS METRICS
=========================================================== */
async function buildClassMetrics(classes) {
  if (!Array.isArray(classes) || classes.length === 0) {
    return {
      classPerformanceData: [],
      classAttendanceData: [],
    };
  }

  const classIds = uniqueIds(classes.map((classe) => classe._id));

  const students = await User.find({
    role: { $in: ["etudiant", "student"] },
    classe: { $in: classIds },
  })
    .select("_id classe")
    .lean();

  if (students.length === 0) {
    return {
      classPerformanceData: classes.map((classe, index) => ({
        class: classe.nom || "Classe",
        average: 0,
        color: CLASS_COLORS[index % CLASS_COLORS.length],
      })),
      classAttendanceData: classes.map((classe, index) => ({
        class: classe.nom || "Classe",
        attendance: 0,
        color: CLASS_COLORS[index % CLASS_COLORS.length],
      })),
    };
  }

  const studentIds = students.map((student) => student._id);
  const studentClassMap = new Map(
    students.map((student) => [
      objectIdToString(student._id),
      objectIdToString(student.classe),
    ])
  );

  const [notes, presences] = await Promise.all([
    findDocumentsForStudents(Note, studentIds),
    findDocumentsForStudents(Presence, studentIds),
  ]);

  const notesByClass = new Map();
  const presencesByClass = new Map();

  for (const note of notes) {
    const studentId = objectIdToString(
      note.etudiant || note.student || note.user
    );
    const classId = studentClassMap.get(studentId);

    if (!classId) continue;

    const percentage = extractGradePercentage(note);

    if (!notesByClass.has(classId)) {
      notesByClass.set(classId, []);
    }

    notesByClass.get(classId).push(percentage);
  }

  for (const presence of presences) {
    const studentId = objectIdToString(
      presence.etudiant || presence.student || presence.user
    );
    const classId = studentClassMap.get(studentId);

    if (!classId) continue;

    if (!presencesByClass.has(classId)) {
      presencesByClass.set(classId, []);
    }

    presencesByClass.get(classId).push(presence);
  }

  const classPerformanceData = classes.map((classe, index) => {
    const classId = objectIdToString(classe._id);
    const grades = notesByClass.get(classId) || [];

    return {
      class: classe.nom || "Classe",
      average: averageNumbers(grades),
      color: CLASS_COLORS[index % CLASS_COLORS.length],
    };
  });

  const classAttendanceData = classes.map((classe, index) => {
    const classId = objectIdToString(classe._id);
    const classPresences = presencesByClass.get(classId) || [];

    return {
      class: classe.nom || "Classe",
      attendance: calculateAttendanceRate(classPresences),
      color: CLASS_COLORS[index % CLASS_COLORS.length],
    };
  });

  return {
    classPerformanceData,
    classAttendanceData,
  };
}

/* ===========================================================
   DATABASE HELPERS
=========================================================== */
async function findDocumentsForStudent(Model, userId) {
  return Model.find({
    $or: [
      { etudiant: userId },
      { student: userId },
      { user: userId },
    ],
  }).lean();
}

async function findDocumentsForStudents(Model, studentIds) {
  if (!studentIds.length) {
    return [];
  }

  return Model.find({
    $or: [
      { etudiant: { $in: studentIds } },
      { student: { $in: studentIds } },
      { user: { $in: studentIds } },
    ],
  }).lean();
}

async function findNotesForTeacher(
  teacherId,
  courseIds,
  studentIds
) {
  const conditions = [
    { enseignant: teacherId },
    { teacher: teacherId },
  ];

  if (courseIds.length) {
    conditions.push(
      { cours: { $in: courseIds } },
      { course: { $in: courseIds } }
    );
  }

  if (studentIds.length) {
    conditions.push(
      { etudiant: { $in: studentIds } },
      { student: { $in: studentIds } }
    );
  }

  return Note.find({ $or: conditions }).lean();
}

async function findPresencesForTeacher(
  teacherId,
  sessions,
  studentIds
) {
  const sessionIds = sessions.map((session) => session._id);
  const conditions = [
    { enseignant: teacherId },
    { teacher: teacherId },
  ];

  if (sessionIds.length) {
    conditions.push(
      { seance: { $in: sessionIds } },
      { session: { $in: sessionIds } }
    );
  }

  if (studentIds.length) {
    conditions.push(
      { etudiant: { $in: studentIds } },
      { student: { $in: studentIds } }
    );
  }

  return Presence.find({ $or: conditions }).lean();
}

async function getRecentAnnouncements() {
  const announcements = await Announcement.find({
    estActif: true,
  })
    .populate({
      path: "auteur",
      select: "prenom nom",
    })
    .sort({ createdAt: -1 })
    .limit(4)
    .lean();

  return announcements.map((announcement) => ({
    _id: announcement._id,
    title: announcement.titre || "Announcement",
    description: truncateText(announcement.contenu || "", 100),
    date: getTimeAgo(announcement.createdAt),
    type: announcement.type || "info",
    icon: getAnnouncementIcon(announcement.type),
    author: getFullName(announcement.auteur),
  }));
}

/* ===========================================================
   SESSIONS HELPERS
=========================================================== */
function filterTodaySessions(sessions) {
  const today = getFrenchDayName();

  return sessions.filter(
    (session) => normalizeText(session.jourSemaine) === normalizeText(today)
  );
}

function mapTeacherSession(session) {
  return {
    _id: session._id,
    day: session.jourSemaine || "",
    startTime: session.heureDebut || "",
    endTime: session.heureFin || "",
    courseName: getCourseName(session.cours),
    className: session.classe?.nom || "",
    room: session.salle || "",
  };
}

function mapStudentSession(session) {
  return {
    _id: session._id,
    day: session.jourSemaine || "",
    startTime: session.heureDebut || "",
    endTime: session.heureFin || "",
    courseName: getCourseName(session.cours),
    room: session.salle || "",
    teacherName: getFullName(session.enseignant),
  };
}

function buildTeacherCourses(sessions) {
  const courses = new Map();

  for (const session of sessions) {
    const courseId = objectIdToString(
      session.cours?._id || session.cours
    );

    if (!courseId || courses.has(courseId)) continue;

    courses.set(courseId, {
      _id: session.cours?._id || session.cours,
      name: getCourseName(session.cours),
    });
  }

  return Array.from(courses.values());
}

/* ===========================================================
   ACTIVITY HELPERS
=========================================================== */
function buildTeacherRecentActivity(notes, presences) {
  const noteActivities = notes.map((note) => ({
    action: "Grade added or updated",
    user: `Student ${objectIdToString(
      note.etudiant || note.student || note.user
    )}`,
    time: getTimeAgo(note.updatedAt || note.createdAt),
    rawDate: note.updatedAt || note.createdAt,
    icon: "📝",
    color: "from-purple-500 to-pink-400",
  }));

  const presenceActivities = presences.map((presence) => ({
    action: "Attendance recorded",
    user: `Student ${objectIdToString(
      presence.etudiant || presence.student || presence.user
    )}`,
    time: getTimeAgo(presence.updatedAt || presence.createdAt),
    rawDate: presence.updatedAt || presence.createdAt,
    icon: "✅",
    color: "from-blue-500 to-cyan-400",
  }));

  return [...noteActivities, ...presenceActivities]
    .sort((a, b) => new Date(b.rawDate || 0) - new Date(a.rawDate || 0))
    .slice(0, 5)
    .map(({ rawDate, ...activity }) => activity);
}

function buildStudentRecentActivity(notes, presences) {
  const noteActivities = notes.map((note) => ({
    action: "New grade available",
    user: `${extractGradePercentage(note)}%`,
    time: getTimeAgo(note.updatedAt || note.createdAt),
    rawDate: note.updatedAt || note.createdAt,
    icon: "🎓",
    color: "from-purple-500 to-pink-400",
  }));

  const presenceActivities = presences.map((presence) => ({
    action: isPresentPresence(presence)
      ? "Marked present"
      : "Marked absent",
    user: normalizePresenceStatus(presence.statut || presence.status),
    time: getTimeAgo(presence.updatedAt || presence.createdAt),
    rawDate: presence.updatedAt || presence.createdAt,
    icon: isPresentPresence(presence) ? "✅" : "⚠️",
    color: isPresentPresence(presence)
      ? "from-blue-500 to-cyan-400"
      : "from-pink-500 to-orange-400",
  }));

  return [...noteActivities, ...presenceActivities]
    .sort((a, b) => new Date(b.rawDate || 0) - new Date(a.rawDate || 0))
    .slice(0, 5)
    .map(({ rawDate, ...activity }) => activity);
}

/* ===========================================================
   CALCULATION HELPERS
=========================================================== */
function calculateGenderData(maleCount, femaleCount) {
  const total = maleCount + femaleCount;

  if (total === 0) {
    return {
      male: 0,
      female: 0,
      maleCount: 0,
      femaleCount: 0,
    };
  }

  const male = Math.round((maleCount / total) * 100);
  const female = 100 - male;

  return {
    male,
    female,
    maleCount,
    femaleCount,
  };
}

function calculateAttendanceRate(presences) {
  if (!Array.isArray(presences) || presences.length === 0) {
    return 0;
  }

  const presentCount = presences.filter(isPresentPresence).length;

  return Math.round((presentCount / presences.length) * 100);
}

function calculateAverageGrade(notes, examMap = null) {
  if (!Array.isArray(notes) || notes.length === 0) {
    return 0;
  }

  const percentages = notes
    .map((note) => {
      const examId = objectIdToString(note.examen || note.exam);
      const exam = examMap?.get(examId) || null;

      return extractGradePercentage(note, exam);
    })
    .filter(Number.isFinite);

  return averageNumbers(percentages);
}

function extractGradeValue(note) {
  const candidates = [
    note?.note,
    note?.valeur,
    note?.noteObtenue,
    note?.score,
    note?.grade,
  ];

  const value = candidates.find(
    (candidate) =>
      candidate !== undefined &&
      candidate !== null &&
      Number.isFinite(Number(candidate))
  );

  return value === undefined ? 0 : Number(value);
}

function extractGradePercentage(note, exam = null) {
  const value = extractGradeValue(note);
  const maxGrade = extractMaxGrade(note, exam);

  if (maxGrade > 0) {
    return clampPercentage((value / maxGrade) * 100);
  }

  // Une note <= 20 est considérée comme une note sur 20.
  if (value >= 0 && value <= 20) {
    return clampPercentage(value * 5);
  }

  // Sinon elle est considérée comme déjà exprimée en pourcentage.
  return clampPercentage(value);
}

function extractMaxGrade(note, exam = null) {
  const totalCandidates = [
    note?.noteTotale,
    note?.bareme,
    note?.total,
    note?.maxNote,
    note?.maxScore,
    note?.noteMax,
    exam?.noteMax,
    exam?.noteTotale,
    exam?.bareme,
    exam?.maxNote,
    exam?.maxScore,
  ];

  const totalValue = totalCandidates.find(
    (candidate) =>
      candidate !== undefined &&
      candidate !== null &&
      Number(candidate) > 0
  );

  // Dans l'application, les notes sont généralement sur 20.
  return totalValue !== undefined ? Number(totalValue) : 20;
}

function averageNumbers(values) {
  if (!Array.isArray(values) || values.length === 0) {
    return 0;
  }

  const validValues = values
    .map(Number)
    .filter(Number.isFinite);

  if (validValues.length === 0) {
    return 0;
  }

  const total = validValues.reduce((sum, value) => sum + value, 0);

  return Math.round(total / validValues.length);
}

function clampPercentage(value) {
  return Math.round(Math.max(0, Math.min(100, Number(value) || 0)));
}

/* ===========================================================
   PRESENCE HELPERS
=========================================================== */
function isPresentPresence(presence) {
  const status = normalizeText(
    presence?.statut || presence?.status || ""
  );

  return [
    "present",
    "presente",
    "oui",
    "true",
    "p",
  ].includes(status);
}

function isAbsentPresence(presence) {
  return !isPresentPresence(presence);
}

function normalizePresenceStatus(status) {
  return String(status || "Unknown");
}

/* ===========================================================
   AUTHENTICATION HELPERS
=========================================================== */
async function resolveAuthenticatedUser(req) {
  if (req.user) {
    return req.user;
  }

  const authorizationHeader = req.headers?.authorization || "";

  const bearerToken = authorizationHeader.startsWith("Bearer ")
    ? authorizationHeader.slice(7).trim()
    : null;

  const token =
    req.cookies?.jwt ||
    req.cookies?.token ||
    req.cookies?.accessToken ||
    bearerToken;

  if (!token) {
    return null;
  }

  const decoded = jwt.verify(token, process.env.JWT_SECRET);

  const decodedUserId =
    decoded?.id ||
    decoded?._id ||
    decoded?.userId;

  if (!decodedUserId) {
    return null;
  }

  const user = await User.findById(decodedUserId).select("-password");

  if (user) {
    req.user = user;
  }

  return user;
}

function normalizeUserRole(role) {
  const normalizedRole = normalizeText(role);

  const roleAliases = {
    admin: "admin",
    administrator: "admin",
    administrateur: "admin",

    enseignant: "enseignant",
    teacher: "enseignant",
    prof: "enseignant",
    professeur: "enseignant",

    etudiant: "etudiant",
    student: "etudiant",
    eleve: "etudiant",
  };

  return roleAliases[normalizedRole] || "";
}

/* ===========================================================
   GENERAL HELPERS
=========================================================== */
function getUserId(user) {
  return user?._id || user?.id || null;
}

function normalizeRange(range) {
  return ["week", "month", "year"].includes(range)
    ? range
    : "week";
}

function getFrenchDayName() {
  const frenchDays = [
    "Dimanche",
    "Lundi",
    "Mardi",
    "Mercredi",
    "Jeudi",
    "Vendredi",
    "Samedi",
  ];

  return frenchDays[new Date().getDay()];
}

function normalizeText(value) {
  return String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .trim()
    .toLowerCase();
}

function uniqueIds(ids) {
  const idsMap = new Map();

  for (const id of ids) {
    const stringId = objectIdToString(id);

    if (stringId) {
      idsMap.set(stringId, id);
    }
  }

  return Array.from(idsMap.values());
}

function deduplicateDocuments(documents) {
  const documentsMap = new Map();

  for (const document of documents) {
    const id = objectIdToString(document?._id);

    if (id && !documentsMap.has(id)) {
      documentsMap.set(id, document);
    }
  }

  return Array.from(documentsMap.values());
}

function objectIdToString(value) {
  if (!value) return "";

  if (value._id) {
    return String(value._id);
  }

  return String(value);
}

function getCourseName(course) {
  if (!course) return "";

  if (typeof course === "string") {
    return course;
  }

  return course.nom || course.titre || "";
}

function getExamName(exam) {
  if (!exam) return "";

  if (typeof exam === "string") {
    return "";
  }

  return exam.titre || exam.nom || exam.name || "";
}

function getFullName(user) {
  if (!user || typeof user !== "object") {
    return "";
  }

  return [user.prenom, user.nom].filter(Boolean).join(" ");
}

function truncateText(text, maxLength) {
  const safeText = String(text || "");

  if (safeText.length <= maxLength) {
    return safeText;
  }

  return `${safeText.substring(0, maxLength)}...`;
}

function sortByNewest(a, b) {
  const dateA = new Date(a.updatedAt || a.createdAt || 0);
  const dateB = new Date(b.updatedAt || b.createdAt || 0);

  return dateB - dateA;
}

function getUserActivityLabel(role) {
  const normalizedRole = normalizeUserRole(role) || role;

  const labels = {
    admin: "Administrator registered",
    enseignant: "Teacher registered",
    etudiant: "Student registered",
  };

  return labels[normalizedRole] || "User registered";
}

function getRoleIcon(role) {
  const normalizedRole = normalizeUserRole(role) || role;

  const icons = {
    admin: "🛡️",
    enseignant: "👨‍🏫",
    etudiant: "👥",
  };

  return icons[normalizedRole] || "👤";
}

function getRoleColor(role) {
  const normalizedRole = normalizeUserRole(role) || role;

  const colors = {
    admin: "from-red-500 to-orange-400",
    enseignant: "from-purple-500 to-pink-400",
    etudiant: "from-blue-500 to-cyan-400",
  };

  return colors[normalizedRole] || "from-gray-500 to-slate-400";
}

function getAnnouncementIcon(type) {
  const icons = {
    holiday: "🎄",
    meeting: "👥",
    course: "🚀",
    exam: "📝",
    info: "ℹ️",
    warning: "⚠️",
    success: "✅",
  };

  return icons[type] || "📢";
}

function getTimeAgo(date) {
  if (!date) return "";

  const now = new Date();
  const targetDate = new Date(date);

  if (Number.isNaN(targetDate.getTime())) {
    return "";
  }

  const diffInMs = Math.max(0, now - targetDate);
  const diffInMinutes = Math.floor(diffInMs / (1000 * 60));
  const diffInHours = Math.floor(diffInMs / (1000 * 60 * 60));
  const diffInDays = Math.floor(diffInHours / 24);

  if (diffInMinutes < 1) return "Just now";
  if (diffInMinutes < 60) return `${diffInMinutes} minutes ago`;
  if (diffInHours < 24) return `${diffInHours} hours ago`;
  if (diffInDays === 1) return "1 day ago";
  if (diffInDays < 7) return `${diffInDays} days ago`;

  return targetDate.toLocaleDateString();
}

// Optionnel : permet de vider manuellement le cache après une création,
// modification ou suppression d'une note, présence, séance, classe, etc.
exports.clearDashboardCache = () => {
  cache.flushAll();
};
