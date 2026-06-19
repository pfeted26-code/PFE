import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import {
  Activity,
  AlertCircle,
  Award,
  Bell,
  BookOpen,
  CalendarDays,
  CheckCircle2,
  ChevronRight,
  Clock3,
  FileText,
  GraduationCap,
  Loader2,
  MessageSquare,
  RefreshCw,
  Send,
  TrendingUp,
  UserCheck,
} from "lucide-react";

import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { getDashboardStats } from "@/services/dashboardService";

const ICONS = {
  "📚": BookOpen,
  "📝": FileText,
  "📈": TrendingUp,
  "🎓": Award,
  "📩": Send,
  "📊": TrendingUp,
  "🔔": Bell,
  "✅": CheckCircle2,
  "⚠️": AlertCircle,
};

const DEFAULT_STATS = [
  {
    title: "My Courses",
    value: "0",
    icon: "📚",
    color: "from-blue-500 to-cyan-500",
    change: "",
  },
  {
    title: "Average Grade",
    value: "0%",
    icon: "🎓",
    color: "from-violet-500 to-purple-500",
    change: "",
  },
  {
    title: "Attendance Rate",
    value: "0%",
    icon: "✅",
    color: "from-emerald-500 to-teal-500",
    change: "",
  },
  {
    title: "Absences",
    value: "0",
    icon: "⚠️",
    color: "from-orange-500 to-amber-500",
    change: "",
  },
];

const STUDENT_SERVICES = [
  {
    title: "My Courses",
    description: "Access lessons, documents, and learning resources.",
    link: "/student/courses",
    icon: BookOpen,
    color: "from-blue-500 to-cyan-500",
  },
  {
    title: "Timetable",
    description: "View today’s classes and your weekly timetable.",
    link: "/student/timetable",
    icon: CalendarDays,
    color: "from-indigo-500 to-blue-500",
  },
  {
    title: "Exams & Grades",
    description: "Consult your exams, grades, and academic results.",
    link: "/student/exams",
    icon: FileText,
    color: "from-orange-500 to-amber-500",
  },
  {
    title: "Attendance",
    description: "Follow your attendance history and absences.",
    link: "/student/attendance",
    icon: UserCheck,
    color: "from-emerald-500 to-teal-500",
  },
  {
    title: "Requests",
    description: "Send and track your administrative requests.",
    link: "/student/requests",
    icon: Send,
    color: "from-violet-500 to-purple-500",
  },
  {
    title: "Announcements",
    description: "Read the latest information from the school.",
    link: "/student/notifications",
    icon: Bell,
    color: "from-pink-500 to-rose-500",
  },
];

export default function StudentDashboard() {
  const [dashboardData, setDashboardData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState("");

  const loadDashboard = async ({ silent = false } = {}) => {
    try {
      if (silent) {
        setRefreshing(true);
      } else {
        setLoading(true);
      }

      setError("");

      const data = await getDashboardStats("week");

      if (data?.dashboardType && data.dashboardType !== "etudiant") {
        throw new Error("The returned dashboard is not a student dashboard.");
      }

      setDashboardData(data || {});
    } catch (err) {
      console.error("Student dashboard error:", err);

      setError(
        err?.response?.data?.message ||
          err?.message ||
          "We could not load your student information."
      );
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadDashboard();
  }, []);

  const studentName =
    dashboardData?.student?.fullName ||
    dashboardData?.student?.name ||
    dashboardData?.user?.fullName ||
    dashboardData?.user?.name ||
    "Student";

  const studentClass =
    dashboardData?.student?.class ||
    dashboardData?.student?.className ||
    "Student space";

  const todaySessions = Array.isArray(dashboardData?.todaysSessions)
    ? dashboardData.todaysSessions
    : [];

  const weeklySchedule = Array.isArray(dashboardData?.weeklySchedule)
    ? dashboardData.weeklySchedule
    : [];

  const recentNotes = Array.isArray(dashboardData?.recentNotes)
    ? dashboardData.recentNotes
    : [];

  const recentActivity = Array.isArray(dashboardData?.recentActivity)
    ? dashboardData.recentActivity
    : [];

  const announcements = Array.isArray(dashboardData?.announcements)
    ? dashboardData.announcements
    : [];

  const stats = useMemo(() => {
    const backendStats = Array.isArray(dashboardData?.stats)
      ? dashboardData.stats
      : [];

    return DEFAULT_STATS.map((fallback) => {
      const item =
        backendStats.find((stat) => stat?.title === fallback.title) ||
        fallback;

      return {
        label: item?.title || fallback.title,
        value: item?.value ?? fallback.value,
        icon: ICONS[item?.icon] || ICONS[fallback.icon] || BookOpen,
        color: item?.color || fallback.color,
        change: item?.change || "",
      };
    });
  }, [dashboardData]);

  const todayLabel = useMemo(
    () =>
      new Intl.DateTimeFormat("en", {
        weekday: "long",
        day: "numeric",
        month: "long",
        year: "numeric",
      }).format(new Date()),
    []
  );

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-background via-background to-primary/5 px-6">
        <div className="text-center">
          <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-600 to-violet-600 shadow-xl shadow-blue-500/20">
            <Loader2 className="h-7 w-7 animate-spin text-white" />
          </div>

          <h2 className="mt-5 text-xl font-bold">
            Preparing your dashboard
          </h2>

          <p className="mt-2 text-sm text-muted-foreground">
            Loading courses, timetable, grades, and attendance…
          </p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-background via-background to-primary/5 px-6">
        <Card className="w-full max-w-lg border-destructive/20 p-8 text-center shadow-xl">
          <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-destructive/10">
            <AlertCircle className="h-7 w-7 text-destructive" />
          </div>

          <h2 className="mt-5 text-2xl font-bold">
            Dashboard unavailable
          </h2>

          <p className="mt-3 text-sm leading-6 text-muted-foreground">
            {error}
          </p>

          <button
            type="button"
            onClick={() => loadDashboard()}
            className="mt-6 inline-flex items-center gap-2 rounded-xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground transition hover:opacity-90"
          >
            <RefreshCw className="h-4 w-4" />
            Try again
          </button>
        </Card>
      </div>
    );
  }

  return (
    <main className="min-h-screen bg-gradient-to-br from-background via-background to-primary/5">
      <div className="container mx-auto space-y-6 px-4 py-5 sm:px-6 lg:px-8">
        {/* Hero */}
        <section className="relative overflow-hidden rounded-[28px] bg-gradient-to-br from-blue-700 via-indigo-700 to-violet-700 p-6 text-white shadow-2xl shadow-blue-900/20 sm:p-8">
          <div className="absolute -right-20 -top-24 h-72 w-72 rounded-full bg-white/10 blur-2xl" />
          <div className="absolute -bottom-28 left-1/3 h-64 w-64 rounded-full bg-cyan-300/10 blur-3xl" />

          <div className="relative flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-xs font-semibold backdrop-blur">
                <GraduationCap className="h-4 w-4" />
                Student workspace
              </div>

              <h1 className="max-w-3xl text-3xl font-black tracking-tight sm:text-4xl lg:text-5xl">
                Welcome back, {studentName}
              </h1>

              <p className="mt-3 max-w-2xl text-sm leading-6 text-blue-100 sm:text-base">
                Follow your classes, grades, attendance, announcements, and
                academic progress from one place.
              </p>

              <div className="mt-5 flex flex-wrap items-center gap-3 text-xs text-blue-100 sm:text-sm">
                <span className="inline-flex items-center gap-2 rounded-full bg-black/10 px-3 py-2 backdrop-blur">
                  <CalendarDays className="h-4 w-4" />
                  {todayLabel}
                </span>

                <span className="inline-flex items-center gap-2 rounded-full bg-black/10 px-3 py-2 backdrop-blur">
                  <GraduationCap className="h-4 w-4" />
                  {studentClass}
                </span>
              </div>
            </div>

            <div className="flex flex-wrap gap-3">
              

              <Link
                to="/student/courses"
                className="inline-flex h-11 items-center justify-center gap-2 rounded-xl bg-white px-4 text-sm font-semibold text-indigo-700 transition hover:bg-white/90"
              >
                <BookOpen className="h-4 w-4" />
                Continue learning
              </Link>
            </div>
          </div>
        </section>

        {/* Main statistics */}
        <section className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {stats.map((stat) => {
            const Icon = stat.icon;

            return (
              <Card
                key={stat.label}
                className="group relative overflow-hidden border p-5 shadow-lg transition duration-300 hover:-translate-y-1 hover:shadow-xl"
              >
                <div
                  className={`absolute inset-x-0 top-0 h-1 bg-gradient-to-r ${stat.color}`}
                />

                <div
                  className={`absolute -right-10 -top-10 h-32 w-32 rounded-full bg-gradient-to-br ${stat.color} opacity-[0.08] blur-2xl`}
                />

                <div className="relative">
                  <div className="flex items-start justify-between gap-3">
                    <div
                      className={`flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br ${stat.color} shadow-lg`}
                    >
                      <Icon className="h-6 w-6 text-white" />
                    </div>

                    {String(stat.change || "").trim() !== "" && (
                      <Badge variant="secondary" className="text-[11px]">
                        {stat.change}
                      </Badge>
                    )}
                  </div>

                  <p className="mt-6 text-3xl font-black tracking-tight">
                    {stat.value}
                  </p>

                  <p className="mt-1 text-sm font-medium text-muted-foreground">
                    {stat.label}
                  </p>
                </div>
              </Card>
            );
          })}
        </section>

        {/* Today and grades */}
        <section className="grid grid-cols-1 gap-6 xl:grid-cols-2">
          <Card className="border p-5 shadow-lg sm:p-6">
            <SectionTitle
              icon={Clock3}
              title="Today’s classes"
              subtitle="Your teaching schedule for today"
              link="/student/timetable"
            />

            {todaySessions.length > 0 ? (
              <div className="space-y-3">
                {todaySessions.slice(0, 4).map((session, index) => (
                  <div
                    key={session?._id || index}
                    className="flex items-center gap-4 rounded-2xl border bg-muted/20 p-4 transition hover:bg-muted/40"
                  >
                    <div className="flex h-16 w-20 shrink-0 flex-col items-center justify-center rounded-2xl bg-gradient-to-br from-blue-600 to-violet-600 text-white shadow-lg">
                      <span className="text-sm font-black">
                        {session?.startTime || "--:--"}
                      </span>

                      <span className="text-[11px] text-white/80">
                        {session?.endTime || "--:--"}
                      </span>
                    </div>

                    <div className="min-w-0 flex-1">
                      <p className="truncate text-base font-bold">
                        {session?.courseName || "Course"}
                      </p>

                      <p className="mt-1 truncate text-xs text-muted-foreground">
                        {[
                          session?.room && `Room ${session.room}`,
                          session?.teacherName,
                        ]
                          .filter(Boolean)
                          .join(" • ") || "Class session"}
                      </p>
                    </div>

                    <Badge variant="outline">Today</Badge>
                  </div>
                ))}
              </div>
            ) : (
              <EmptyState
                icon={CheckCircle2}
                title="No classes scheduled today"
                text="Use the time to review your lessons or prepare for your next class."
              />
            )}
          </Card>

          <Card className="border p-5 shadow-lg sm:p-6">
            <SectionTitle
              icon={Award}
              title="Recent grades"
              subtitle="Your latest published academic results"
              link="/student/exams"
            />

            {recentNotes.length > 0 ? (
              <div className="space-y-3">
                {recentNotes.slice(0, 4).map((note, index) => (
                  <div
                    key={note?._id || index}
                    className="flex items-center gap-4 rounded-2xl border bg-muted/20 p-4 transition hover:bg-muted/40"
                  >
                    <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-violet-500/10">
                      <Award className="h-5 w-5 text-violet-600" />
                    </div>

                    <div className="min-w-0 flex-1">
                      <p className="truncate font-bold">
                        {note?.examName || "Exam"}
                      </p>

                      <p className="mt-1 truncate text-xs text-muted-foreground">
                        {[
                          note?.courseName,
                          note?.examType,
                          formatDate(note?.examDate || note?.date),
                        ]
                          .filter(Boolean)
                          .join(" • ")}
                      </p>
                    </div>

                    <div className="text-right">
                      <Badge variant="secondary">
                        {formatGrade(note)}
                      </Badge>

                      <p className="mt-1 text-[11px] text-muted-foreground">
                        {Number(note?.percentage) || 0}%
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <EmptyState
                icon={Award}
                title="No grades available"
                text="Your grades will appear here after publication."
              />
            )}
          </Card>
        </section>

        {/* Services without repeated statistics */}
        <section>
          <div className="mb-4">
            <p className="text-sm font-semibold text-primary">
              Student services
            </p>

            <h2 className="mt-1 text-2xl font-black">
              Everything you need
            </h2>
          </div>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
            {STUDENT_SERVICES.map((service) => {
              const Icon = service.icon;

              return (
                <Link key={service.title} to={service.link} className="group">
                  <Card className="relative h-full overflow-hidden border p-5 shadow-lg transition duration-300 group-hover:-translate-y-1 group-hover:shadow-xl">
                    <div
                      className={`absolute inset-0 bg-gradient-to-br ${service.color} opacity-[0.05]`}
                    />

                    <div className="relative flex h-full flex-col">
                      <div
                        className={`flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br ${service.color} shadow-lg transition group-hover:scale-110`}
                      >
                        <Icon className="h-6 w-6 text-white" />
                      </div>

                      <h3 className="mt-5 text-lg font-black">
                        {service.title}
                      </h3>

                      <p className="mt-2 flex-1 text-sm leading-6 text-muted-foreground">
                        {service.description}
                      </p>

                      <div className="mt-5 flex items-center justify-between text-sm font-semibold">
                        <span>Open service</span>
                        <ChevronRight className="h-4 w-4 transition group-hover:translate-x-1" />
                      </div>
                    </div>
                  </Card>
                </Link>
              );
            })}
          </div>
        </section>

        {/* Weekly schedule */}
        <Card className="border p-5 shadow-lg sm:p-6">
          <SectionTitle
            icon={CalendarDays}
            title="Weekly schedule"
            subtitle="Your next scheduled classes"
            link="/student/timetable"
          />

          {weeklySchedule.length > 0 ? (
            <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
              {weeklySchedule.slice(0, 6).map((session, index) => (
                <div
                  key={session?._id || index}
                  className="rounded-2xl border bg-muted/20 p-4 transition hover:bg-muted/40"
                >
                  <div className="mb-3 flex items-center justify-between gap-3">
                    <Badge variant="outline">
                      {session?.day || "Scheduled"}
                    </Badge>

                    <span className="text-xs font-bold text-primary">
                      {session?.startTime || "--:--"} -{" "}
                      {session?.endTime || "--:--"}
                    </span>
                  </div>

                  <p className="font-bold">
                    {session?.courseName || "Course"}
                  </p>

                  <p className="mt-1 text-xs text-muted-foreground">
                    {[
                      session?.room && `Room ${session.room}`,
                      session?.teacherName,
                    ]
                      .filter(Boolean)
                      .join(" • ") || "Class session"}
                  </p>
                </div>
              ))}
            </div>
          ) : (
            <EmptyState
              icon={CalendarDays}
              title="No timetable available"
              text="Your weekly classes will appear here when they are scheduled."
            />
          )}
        </Card>

        {/* Activity and announcements */}
        <section className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <Card className="border p-5 shadow-lg sm:p-6">
            <SectionTitle
              icon={Activity}
              title="Recent activity"
              subtitle="Latest updates from your student space"
              link="/student/notifications"
            />

            {recentActivity.length > 0 ? (
              <div className="space-y-2">
                {recentActivity.slice(0, 5).map((activity, index) => {
                  const Icon = ICONS[activity?.icon] || Bell;

                  return (
                    <div
                      key={activity?._id || index}
                      className="flex items-start gap-3 rounded-xl p-3 transition hover:bg-muted/50"
                    >
                      <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary/10">
                        <Icon className="h-5 w-5 text-primary" />
                      </div>

                      <div className="min-w-0 flex-1">
                        <p className="text-sm font-bold">
                          {activity?.action || "Student activity"}
                        </p>

                        <p className="truncate text-sm text-muted-foreground">
                          {activity?.user || ""}
                        </p>

                        <p className="mt-1 text-xs text-muted-foreground">
                          {activity?.time || "Recently"}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <EmptyState
                icon={Activity}
                title="No recent activity"
                text="New grades and attendance updates will appear here."
              />
            )}
          </Card>

          <Card className="border p-5 shadow-lg sm:p-6">
            <SectionTitle
              icon={MessageSquare}
              title="Announcements"
              subtitle="Latest school information"
              link="/student/notifications"
            />

            {announcements.length > 0 ? (
              <div className="space-y-3">
                {announcements.slice(0, 4).map((announcement, index) => (
                  <div
                    key={announcement?._id || index}
                    className="rounded-2xl border bg-muted/20 p-4 transition hover:bg-muted/40"
                  >
                    <div className="flex items-start gap-3">
                      <div className="text-xl">
                        {announcement?.icon || "📢"}
                      </div>

                      <div className="min-w-0 flex-1">
                        <p className="font-bold">
                          {announcement?.title || "Announcement"}
                        </p>

                        <p className="mt-1 line-clamp-2 text-sm leading-6 text-muted-foreground">
                          {announcement?.description || "No description"}
                        </p>

                        <p className="mt-2 text-xs text-muted-foreground">
                          {[announcement?.author, announcement?.date]
                            .filter(Boolean)
                            .join(" • ")}
                        </p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <EmptyState
                icon={MessageSquare}
                title="No announcements"
                text="The latest school announcements will appear here."
              />
            )}
          </Card>
        </section>
      </div>
    </main>
  );
}

function SectionTitle({ icon: Icon, title, subtitle, link }) {
  return (
    <div className="mb-5 flex items-center justify-between gap-3">
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10">
          <Icon className="h-5 w-5 text-primary" />
        </div>

        <div>
          <h2 className="font-black">{title}</h2>
          <p className="text-xs text-muted-foreground">{subtitle}</p>
        </div>
      </div>

      <Link
        to={link}
        className="shrink-0 text-sm font-semibold text-primary hover:underline"
      >
        View all
      </Link>
    </div>
  );
}

function EmptyState({ icon: Icon, title, text }) {
  return (
    <div className="flex min-h-40 flex-col items-center justify-center rounded-2xl border border-dashed p-6 text-center">
      <Icon className="h-9 w-9 text-muted-foreground/50" />
      <p className="mt-3 text-sm font-bold">{title}</p>
      <p className="mt-1 max-w-xs text-xs leading-5 text-muted-foreground">
        {text}
      </p>
    </div>
  );
}

function formatGrade(note) {
  const value = Number(note?.value);
  const maxGrade = Number(note?.maxGrade);
  const percentage = Number(note?.percentage);

  if (
    Number.isFinite(value) &&
    value >= 0 &&
    Number.isFinite(maxGrade) &&
    maxGrade > 0
  ) {
    return `${value}/${maxGrade}`;
  }

  if (Number.isFinite(value) && value >= 0) {
    return `${value}`;
  }

  if (Number.isFinite(percentage)) {
    return `${percentage}%`;
  }

  return "Not available";
}

function formatDate(date) {
  if (!date) {
    return "Recently published";
  }

  const parsedDate = new Date(date);

  if (Number.isNaN(parsedDate.getTime())) {
    return String(date);
  }

  return new Intl.DateTimeFormat("en", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(parsedDate);
}
