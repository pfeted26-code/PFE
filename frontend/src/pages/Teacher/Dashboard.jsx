import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Activity,
  AlertCircle,
  Award,
  BarChart3,
  Bell,
  BookOpen,
  CalendarDays,
  CheckCircle2,
  ChevronRight,
  ClipboardCheck,
  Clock3,
  GraduationCap,
  Loader2,
  LogOut,
  Megaphone,
  RefreshCw,
  School,
  TrendingUp,
  UserCheck,
  Users,
} from "lucide-react";

import { useAuth } from "@/hooks/useAuth";
import { getDashboardStats } from "@/services/dashboardService";
import { getNotificationsByUser } from "@/services/notificationService";
import { ROUTES } from "@/constants/routes";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

const STAT_ICONS = {
  "My Courses": BookOpen,
  "My Classes": School,
  "My Students": Users,
  "Attendance Rate": Activity,
};

const QUICK_ACTIONS = [
  {
    title: "Grade Assignments",
    description: "Review grades and student results.",
    icon: ClipboardCheck,
    color: "from-orange-500 to-red-500",
    routeKey: "TEACHER_GRADING",
  },
  {
    title: "Take Attendance",
    description: "Record attendance for your classes.",
    icon: UserCheck,
    color: "from-blue-500 to-cyan-500",
    routeKey: "TEACHER_ATTENDANCE",
  },
  {
    title: "View Students",
    description: "Consult students and their progress.",
    icon: Users,
    color: "from-violet-500 to-fuchsia-500",
    routeKey: "TEACHER_STUDENTS",
  },
  {
    title: "My Schedule",
    description: "Open your weekly teaching schedule.",
    icon: CalendarDays,
    color: "from-emerald-500 to-teal-500",
    routeKey: "TEACHER_SCHEDULE",
  },
];

export default function TeacherDashboard() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const [dashboardData, setDashboardData] = useState(null);
  const [notificationCount, setNotificationCount] = useState(0);
  const [selectedSession, setSelectedSession] = useState(null);
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

      // Le backend détecte automatiquement le rôle depuis req.user.
      // Le paramètre correspond à la période et non au rôle.
      const dashboard = await getDashboardStats("week");

      if (
        dashboard?.dashboardType &&
        dashboard.dashboardType !== "enseignant"
      ) {
        throw new Error(
          `The returned dashboard is not a teacher dashboard (${dashboard.dashboardType}).`
        );
      }

      setDashboardData(dashboard || {});

      const currentUserId = user?._id || user?.id;

      if (currentUserId) {
        try {
          const notifications = await getNotificationsByUser(currentUserId);

          const unreadCount = Array.isArray(notifications)
            ? notifications.filter(
                (notification) =>
                  notification?.lu === false ||
                  notification?.read === false
              ).length
            : 0;

          setNotificationCount(unreadCount);
        } catch (notificationError) {
          console.error(
            "Failed to load teacher notifications:",
            notificationError
          );
          setNotificationCount(0);
        }
      }
    } catch (err) {
      console.error("Teacher dashboard error:", err);

      setError(
        err?.response?.data?.message ||
          err?.message ||
          "Failed to load teacher dashboard data."
      );
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadDashboard();
  }, [user?._id, user?.id]);

  const teacher = dashboardData?.teacher || {};
  const summary = dashboardData?.summary || {};

  const stats = Array.isArray(dashboardData?.stats)
    ? dashboardData.stats
    : [];

  const todaysSessions = Array.isArray(dashboardData?.todaysSessions)
    ? dashboardData.todaysSessions
    : [];

  const recentActivity = Array.isArray(dashboardData?.recentActivity)
    ? dashboardData.recentActivity
    : [];

  const recentNotes = Array.isArray(dashboardData?.recentNotes)
    ? dashboardData.recentNotes
    : [];

  const classes = Array.isArray(dashboardData?.classes)
    ? dashboardData.classes
    : [];

  const courses = Array.isArray(dashboardData?.courses)
    ? dashboardData.courses
    : [];

  const classPerformanceData = Array.isArray(
    dashboardData?.classPerformanceData
  )
    ? dashboardData.classPerformanceData
    : [];

  const classAttendanceData = Array.isArray(
    dashboardData?.classAttendanceData
  )
    ? dashboardData.classAttendanceData
    : [];

  const announcements = Array.isArray(dashboardData?.announcements)
    ? dashboardData.announcements
    : [];

  const normalizedStats = useMemo(
    () =>
      stats.map((stat) => {
        const Icon = STAT_ICONS[stat?.title] || BarChart3;
        const color = stat?.color || "from-blue-500 to-violet-500";

        return {
          ...stat,
          Icon,
          color,
        };
      }),
    [stats]
  );

  const teacherName =
    teacher?.fullName ||
    [user?.prenom, user?.nom].filter(Boolean).join(" ") ||
    "Professor";

  const handleLogout = () => {
    logout();
    navigate(ROUTES.LOGIN);
  };

  const navigateToRoute = (routeKey) => {
    const route = ROUTES?.[routeKey];

    if (route) {
      navigate(route);
    }
  };

  const handleTakeAttendance = (event, session) => {
    event.stopPropagation();

    if (ROUTES?.TEACHER_ATTENDANCE) {
      navigate(ROUTES.TEACHER_ATTENDANCE, {
        state: {
          session,
        },
      });
    }
  };

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-background via-background to-primary/5 px-6">
        <div className="text-center">
          <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-600 to-violet-600 shadow-xl shadow-blue-500/20">
            <Loader2 className="h-7 w-7 animate-spin text-white" />
          </div>

          <h2 className="mt-5 text-xl font-bold">
            Loading teacher dashboard
          </h2>

          <p className="mt-2 text-sm text-muted-foreground">
            Preparing your classes, students, and recent activity…
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

          <h2 className="mt-5 text-2xl font-bold">Dashboard unavailable</h2>

          <p className="mt-3 text-sm leading-6 text-muted-foreground">
            {error}
          </p>

          
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

          <div className="relative flex flex-col gap-6 xl:flex-row xl:items-end xl:justify-between">
            <div>
              <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-xs font-semibold backdrop-blur">
                <GraduationCap className="h-4 w-4" />
                Teacher workspace
              </div>

              <h1 className="max-w-3xl text-3xl font-black tracking-tight sm:text-4xl lg:text-5xl">
                Welcome back, {teacherName}
              </h1>

              <p className="mt-3 max-w-2xl text-sm leading-6 text-blue-100 sm:text-base">
                Manage your classes, students, attendance, grades, and daily
                teaching schedule from one place.
              </p>

              <div className="mt-5 flex flex-wrap items-center gap-3 text-xs text-blue-100 sm:text-sm">
                <span className="inline-flex items-center gap-2 rounded-full bg-black/10 px-3 py-2 backdrop-blur">
                  <CalendarDays className="h-4 w-4" />
                  {new Date().toLocaleDateString(undefined, {
                    weekday: "long",
                    year: "numeric",
                    month: "long",
                    day: "numeric",
                  })}
                </span>

                <span className="inline-flex items-center gap-2 rounded-full bg-black/10 px-3 py-2 backdrop-blur">
                  <Bell className="h-4 w-4" />
                  {notificationCount} unread notifications
                </span>
              </div>
            </div>

            <div className="flex flex-wrap gap-3">
              

              
            </div>
          </div>
        </section>

        {/* KPI cards */}
        <section className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {normalizedStats.length > 0 ? (
            normalizedStats.map((stat, index) => {
              const Icon = stat.Icon;

              return (
                <Card
                  key={stat?.title || index}
                  className="group relative overflow-hidden border shadow-lg transition duration-300 hover:-translate-y-1 hover:shadow-xl"
                >
                  <div
                    className={`absolute inset-x-0 top-0 h-1 bg-gradient-to-r ${stat.color}`}
                  />

                  <div
                    className={`absolute -right-10 -top-10 h-32 w-32 rounded-full bg-gradient-to-br ${stat.color} opacity-[0.08] blur-2xl`}
                  />

                  <CardContent className="relative p-5">
                    <div className="flex items-start justify-between gap-4">
                      <div
                        className={`flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br ${stat.color} shadow-lg`}
                      >
                        <Icon className="h-6 w-6 text-white" />
                      </div>

                      {String(stat?.change || "").trim() !== "" && (
                        <span className="rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-bold text-emerald-600">
                          ↗ {stat.change}
                        </span>
                      )}
                    </div>

                    <p className="mt-6 text-3xl font-black tracking-tight">
                      {stat?.value ?? 0}
                    </p>

                    <p className="mt-1 text-sm font-medium text-muted-foreground">
                      {stat?.title || "Statistic"}
                    </p>
                  </CardContent>
                </Card>
              );
            })
          ) : (
            <Card className="sm:col-span-2 xl:col-span-4">
              <CardContent className="p-8 text-center text-muted-foreground">
                No teacher statistics available.
              </CardContent>
            </Card>
          )}
        </section>

        {/* Schedule and activity */}
        <section className="grid grid-cols-1 gap-6 xl:grid-cols-[minmax(0,1.65fr)_minmax(320px,0.85fr)]">
          <Card className="overflow-hidden border shadow-lg">
            <CardHeader className="border-b">
              <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <CardTitle className="flex items-center gap-2 text-xl">
                    <CalendarDays className="h-5 w-5 text-primary" />
                    Today&apos;s classes
                  </CardTitle>

                  <CardDescription className="mt-1">
                    Your active teaching sessions for today
                  </CardDescription>
                </div>

                <Button
                  variant="outline"
                  size="sm"
                  className="gap-2"
                  onClick={() =>
                    navigateToRoute("TEACHER_SCHEDULE")
                  }
                >
                  View full schedule
                  <ChevronRight className="h-4 w-4" />
                </Button>
              </div>
            </CardHeader>

            <CardContent className="p-5">
              {todaysSessions.length > 0 ? (
                <div className="space-y-3">
                  {todaysSessions.map((session, index) => {
                    const sessionId = session?._id || index;
                    const isSelected = selectedSession === sessionId;

                    return (
                      <button
                        key={sessionId}
                        type="button"
                        onClick={() => setSelectedSession(sessionId)}
                        className={`w-full rounded-2xl border p-4 text-left transition ${
                          isSelected
                            ? "border-primary bg-primary/5 shadow-md"
                            : "border-border hover:border-primary/40 hover:bg-muted/40"
                        }`}
                      >
                        <div className="flex flex-col gap-4 lg:flex-row lg:items-center">
                          <div className="flex items-center gap-4 lg:flex-1">
                            <div className="flex h-16 w-20 shrink-0 flex-col items-center justify-center rounded-2xl bg-gradient-to-br from-blue-600 to-violet-600 text-white shadow-lg">
                              <span className="text-sm font-black">
                                {session?.startTime || "--:--"}
                              </span>

                              <span className="text-[11px] text-white/80">
                                {session?.endTime || "--:--"}
                              </span>
                            </div>

                            <div className="min-w-0">
                              <p className="truncate text-lg font-bold">
                                {session?.courseName || "Course"}
                              </p>

                              <div className="mt-2 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                                <span className="inline-flex items-center gap-1 rounded-full bg-muted px-2.5 py-1">
                                  <School className="h-3.5 w-3.5" />
                                  {session?.className || "Class"}
                                </span>

                                <span className="inline-flex items-center gap-1 rounded-full bg-muted px-2.5 py-1">
                                  <Clock3 className="h-3.5 w-3.5" />
                                  {session?.startTime || "--:--"} -{" "}
                                  {session?.endTime || "--:--"}
                                </span>

                                <span className="inline-flex items-center gap-1 rounded-full bg-muted px-2.5 py-1">
                                  Room {session?.room || "N/A"}
                                </span>
                              </div>
                            </div>
                          </div>

                          <Button
                            type="button"
                            size="sm"
                            className="gap-2"
                            onClick={(event) =>
                              handleTakeAttendance(event, session)
                            }
                          >
                            <UserCheck className="h-4 w-4" />
                            Take attendance
                          </Button>
                        </div>
                      </button>
                    );
                  })}
                </div>
              ) : (
                <EmptyState
                  icon={CheckCircle2}
                  title="No classes scheduled today"
                  text="Your next teaching session will appear here."
                />
              )}
            </CardContent>
          </Card>

          <Card className="border shadow-lg">
            <CardHeader className="border-b">
              <CardTitle className="flex items-center gap-2 text-xl">
                <Activity className="h-5 w-5 text-primary" />
                Recent activity
              </CardTitle>

              <CardDescription>
                Latest updates from your classes
              </CardDescription>
            </CardHeader>

            <CardContent className="p-5">
              {recentActivity.length > 0 ? (
                <div className="max-h-[430px] space-y-3 overflow-y-auto pr-1">
                  {recentActivity.slice(0, 6).map((activity, index) => {
                    const Icon =
                      String(activity?.action || "")
                        .toLowerCase()
                        .includes("grade")
                        ? TrendingUp
                        : String(activity?.action || "")
                            .toLowerCase()
                            .includes("attendance")
                        ? UserCheck
                        : Bell;

                    return (
                      <div
                        key={activity?._id || index}
                        className="flex items-start gap-3 rounded-2xl border bg-muted/25 p-4"
                      >
                        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary/10">
                          <Icon className="h-5 w-5 text-primary" />
                        </div>

                        <div className="min-w-0 flex-1">
                          <p className="text-sm font-bold">
                            {activity?.action || "Teacher activity"}
                          </p>

                          <p className="mt-1 truncate text-xs text-muted-foreground">
                            {activity?.user || ""}
                          </p>

                          <p className="mt-2 text-[11px] text-muted-foreground">
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
                  text="Grades and attendance updates will appear here."
                />
              )}
            </CardContent>
          </Card>
        </section>

        {/* Performance and attendance */}
        <section className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <MetricCard
            title="Class performance"
            description="Average grades for your classes"
            icon={TrendingUp}
            data={classPerformanceData}
            valueKey="average"
            fallbackColor="#2563eb"
          />

          <MetricCard
            title="Class attendance"
            description="Attendance rate by class"
            icon={Activity}
            data={classAttendanceData}
            valueKey="attendance"
            fallbackColor="#10b981"
          />
        </section>

        {/* Recent notes and announcements */}
        <section className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <Card className="border shadow-lg">
            <CardHeader className="border-b">
              <CardTitle className="flex items-center gap-2 text-xl">
                <Award className="h-5 w-5 text-primary" />
                Recent grades
              </CardTitle>

              <CardDescription>
                Latest grades recorded for your students
              </CardDescription>
            </CardHeader>

            <CardContent className="p-5">
              {recentNotes.length > 0 ? (
                <div className="space-y-3">
                  {recentNotes.slice(0, 5).map((note, index) => (
                    <div
                      key={note?._id || index}
                      className="flex items-center gap-4 rounded-2xl border bg-muted/25 p-4"
                    >
                      <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-violet-500/10">
                        <Award className="h-5 w-5 text-violet-600" />
                      </div>

                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-bold">
                          Student {note?.studentId || "Unknown"}
                        </p>

                        <p className="mt-1 text-xs text-muted-foreground">
                          {formatDate(note?.date)}
                        </p>
                      </div>

                      <span className="rounded-full bg-violet-500/10 px-3 py-1.5 text-sm font-black text-violet-600">
                        {Number(note?.percentage) || 0}%
                      </span>
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyState
                  icon={Award}
                  title="No recent grades"
                  text="Recently created or updated grades will appear here."
                />
              )}
            </CardContent>
          </Card>

          <Card className="border shadow-lg">
            <CardHeader className="border-b">
              <CardTitle className="flex items-center gap-2 text-xl">
                <Megaphone className="h-5 w-5 text-primary" />
                Announcements
              </CardTitle>

              <CardDescription>
                Latest school information
              </CardDescription>
            </CardHeader>

            <CardContent className="p-5">
              {announcements.length > 0 ? (
                <div className="space-y-3">
                  {announcements.slice(0, 5).map((announcement, index) => (
                    <div
                      key={announcement?._id || index}
                      className="rounded-2xl border bg-muted/25 p-4"
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
                  icon={Megaphone}
                  title="No announcements"
                  text="School announcements will appear here."
                />
              )}
            </CardContent>
          </Card>
        </section>

        {/* Quick actions */}
        <section>
          <div className="mb-4">
            <p className="text-sm font-semibold text-primary">
              Teacher services
            </p>

            <h2 className="mt-1 text-2xl font-black">Quick actions</h2>
          </div>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
            {QUICK_ACTIONS.map((action) => {
              const Icon = action.icon;

              return (
                <button
                  key={action.title}
                  type="button"
                  onClick={() => navigateToRoute(action.routeKey)}
                  className="group text-left"
                >
                  <Card className="relative h-full overflow-hidden border shadow-lg transition duration-300 group-hover:-translate-y-1 group-hover:shadow-xl">
                    <div
                      className={`absolute inset-0 bg-gradient-to-br ${action.color} opacity-[0.05]`}
                    />

                    <CardContent className="relative p-5">
                      <div
                        className={`flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br ${action.color} shadow-lg transition group-hover:scale-110`}
                      >
                        <Icon className="h-7 w-7 text-white" />
                      </div>

                      <h3 className="mt-5 text-lg font-black">
                        {action.title}
                      </h3>

                      <p className="mt-2 text-sm leading-6 text-muted-foreground">
                        {action.description}
                      </p>

                      <div className="mt-5 flex items-center justify-between text-sm font-semibold">
                        <span>Open service</span>
                        <ChevronRight className="h-4 w-4 transition group-hover:translate-x-1" />
                      </div>
                    </CardContent>
                  </Card>
                </button>
              );
            })}
          </div>
        </section>
      </div>
    </main>
  );
}

function MetricCard({
  title,
  description,
  icon: Icon,
  data,
  valueKey,
  fallbackColor,
}) {
  return (
    <Card className="border shadow-lg">
      <CardHeader className="border-b">
        <CardTitle className="flex items-center gap-2 text-xl">
          <Icon className="h-5 w-5 text-primary" />
          {title}
        </CardTitle>

        <CardDescription>{description}</CardDescription>
      </CardHeader>

      <CardContent className="p-5">
        {data.length > 0 ? (
          <div className="max-h-[340px] space-y-5 overflow-y-auto pr-1">
            {data.map((item, index) => {
              const value = Math.max(
                0,
                Math.min(100, Number(item?.[valueKey]) || 0)
              );

              return (
                <div key={item?.class || index}>
                  <div className="mb-2 flex items-center justify-between gap-3">
                    <div className="min-w-0">
                      <p className="truncate text-sm font-bold">
                        {item?.class || "Unknown class"}
                      </p>

                      <p className="mt-0.5 text-[11px] text-muted-foreground">
                        {value >= 80
                          ? "Excellent"
                          : value >= 60
                          ? "Good"
                          : "Needs attention"}
                      </p>
                    </div>

                    <span className="rounded-full bg-primary/10 px-2.5 py-1 text-xs font-black text-primary">
                      {value}%
                    </span>
                  </div>

                  <div className="h-2.5 overflow-hidden rounded-full bg-muted">
                    <div
                      className="h-full rounded-full transition-all duration-700"
                      style={{
                        width: `${value}%`,
                        backgroundColor: item?.color || fallbackColor,
                      }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <EmptyState
            icon={Icon}
            title={`No ${title.toLowerCase()} data`}
            text="This information will appear when data becomes available."
          />
        )}
      </CardContent>
    </Card>
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

function formatDate(date) {
  if (!date) {
    return "Recently updated";
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
