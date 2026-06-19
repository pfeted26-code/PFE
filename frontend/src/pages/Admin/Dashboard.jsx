import { useEffect, useMemo, useRef, useState } from "react";
import { useLocation } from "react-router-dom";
import {
  Activity,
  AlertTriangle,
  BarChart3,
  BookOpen,
  CalendarDays,
  Clock3,
  GraduationCap,
  Megaphone,
  RefreshCw,
  School,
  ShieldCheck,
  TrendingUp,
  Users,
} from "lucide-react";

import { useTheme } from "../../contexts/ThemeContext";
import { getDashboardStats } from "../../services/dashboardService";

const RANGE_OPTIONS = [
  { value: "week", label: "Week" },
  { value: "month", label: "Month" },
  { value: "year", label: "Year" },
];

const STAT_ICONS = {
  "Total Students": Users,
  "Total Teachers": GraduationCap,
  "Active Courses": BookOpen,
  "Attendance Rate": Activity,
};

const SUMMARY_ITEMS = [
  {
    key: "totalAdmins",
    label: "Administrators",
    icon: ShieldCheck,
    accent: "text-rose-600",
    surface: "bg-rose-500/10",
    description: "Platform administrators",
  },
  {
    key: "totalClasses",
    label: "Classes",
    icon: School,
    accent: "text-amber-600",
    surface: "bg-amber-500/10",
    description: "Active school classes",
  },
];

export default function AdminDashboard() {
  const { theme } = useTheme();
  const location = useLocation();

  const routerDashboardData = location.state?.dashboardData ?? null;

  const initialDashboardData =
    routerDashboardData?.dashboardType === "admin"
      ? routerDashboardData
      : null;

  const [timeRange, setTimeRange] = useState("week");
  const [dashboardData, setDashboardData] = useState(initialDashboardData);
  const [loading, setLoading] = useState(!initialDashboardData);
  const [error, setError] = useState("");
  const [refreshing, setRefreshing] = useState(false);

  const isFirstLoad = useRef(true);

  const isDark = theme === "dark";

  const pageBackground = isDark
    ? "bg-slate-950 text-slate-100"
    : "bg-slate-50 text-slate-900";

  const panelClass = isDark
    ? "border-slate-800 bg-slate-900/90 shadow-black/20"
    : "border-slate-200/80 bg-white shadow-slate-200/70";

  const mutedText = isDark ? "text-slate-400" : "text-slate-500";
  const softSurface = isDark ? "bg-slate-800/70" : "bg-slate-50";
  const progressTrack = isDark ? "bg-slate-800" : "bg-slate-100";

  const fetchDashboardData = async ({ silent = false } = {}) => {
    try {
      if (silent) {
        setRefreshing(true);
      } else {
        setLoading(true);
      }

      setError("");

      const data = await getDashboardStats(timeRange);

      if (data?.dashboardType && data.dashboardType !== "admin") {
        throw new Error(
          `The returned dashboard is not an admin dashboard (${data.dashboardType}).`
        );
      }

      setDashboardData(data ?? {});
    } catch (err) {
      console.error("Failed to fetch dashboard data:", err);

      setError(
        err?.response?.data?.message ||
          err?.message ||
          "Unable to load the administrator dashboard."
      );
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    let isMounted = true;

    const loadData = async () => {
      try {
        if (!isMounted) return;
        await fetchDashboardData();
      } catch {
        // Errors are already handled in fetchDashboardData.
      }
    };

    if (isFirstLoad.current && initialDashboardData) {
      isFirstLoad.current = false;
      setLoading(false);
    } else {
      isFirstLoad.current = false;
      loadData();
    }

    return () => {
      isMounted = false;
    };
  }, [timeRange]);

  const stats = Array.isArray(dashboardData?.stats)
    ? dashboardData.stats
    : [];

  const enrollmentData = Array.isArray(dashboardData?.enrollmentData)
    ? dashboardData.enrollmentData
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

  const recentActivity = Array.isArray(dashboardData?.recentActivity)
    ? dashboardData.recentActivity
    : [];

  const summary = dashboardData?.summary ?? {};

  const normalizedEnrollmentData = useMemo(
    () =>
      enrollmentData.map((item) => ({
        ...item,
        count: Number(item?.count) || 0,
      })),
    [enrollmentData]
  );

  const maxCount = useMemo(
    () =>
      Math.max(
        ...normalizedEnrollmentData.map((item) => item.count),
        1
      ),
    [normalizedEnrollmentData]
  );

  const genderData = useMemo(() => {
    const rawGenderData = dashboardData?.genderData ?? {};

    const maleCount = Number(rawGenderData.maleCount) || 0;
    const femaleCount = Number(rawGenderData.femaleCount) || 0;
    const totalCount = maleCount + femaleCount;

    let male = Number(rawGenderData.male);
    let female = Number(rawGenderData.female);

    if (!Number.isFinite(male)) {
      male = totalCount > 0 ? (maleCount / totalCount) * 100 : 0;
    }

    if (!Number.isFinite(female)) {
      female = totalCount > 0 ? (femaleCount / totalCount) * 100 : 0;
    }

    male = Math.max(0, Math.min(100, male));
    female = Math.max(0, Math.min(100, female));

    if (male + female > 100) {
      const sum = male + female;
      male = (male / sum) * 100;
      female = (female / sum) * 100;
    }

    return {
      male,
      female,
      maleCount,
      femaleCount,
    };
  }, [dashboardData]);

  const totalStudents =
    stats.find((stat) => stat?.title === "Total Students")?.value ??
    summary.totalStudents ??
    genderData.maleCount + genderData.femaleCount;

  const circumference = 2 * Math.PI * 88;
  const maleDash = (genderData.male / 100) * circumference;
  const femaleDash = (genderData.female / 100) * circumference;

  const formattedDate = new Intl.DateTimeFormat("en", {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date());

  if (loading) {
    return (
      <div className={`min-h-screen ${pageBackground}`}>
        <div className="mx-auto flex min-h-screen max-w-7xl items-center justify-center px-6">
          <div className="text-center">
            <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-600 to-violet-600 shadow-xl shadow-blue-500/20">
              <RefreshCw className="h-7 w-7 animate-spin text-white" />
            </div>

            <h2 className="mt-5 text-xl font-bold">
              Loading administration dashboard
            </h2>

            <p className={`mt-2 text-sm ${mutedText}`}>
              Preparing statistics, classes, and recent activity…
            </p>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className={`min-h-screen ${pageBackground}`}>
        <div className="mx-auto flex min-h-screen max-w-7xl items-center justify-center px-6">
          <div
            className={`w-full max-w-lg rounded-3xl border p-8 text-center shadow-xl ${panelClass}`}
          >
            <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-red-500/10">
              <AlertTriangle className="h-7 w-7 text-red-500" />
            </div>

            <h2 className="mt-5 text-2xl font-bold">Dashboard unavailable</h2>

            <p className={`mt-3 text-sm leading-6 ${mutedText}`}>
              {error}
            </p>

            <button
              type="button"
              onClick={() => fetchDashboardData()}
              className="mt-6 inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-blue-600 to-violet-600 px-5 py-3 text-sm font-semibold text-white shadow-lg shadow-blue-500/20 transition hover:-translate-y-0.5"
            >
              <RefreshCw className="h-4 w-4" />
              Try again
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <main className={`min-h-screen ${pageBackground}`}>
      <div className="mx-auto max-w-7xl space-y-6 px-4 py-5 sm:px-6 lg:px-8">
        {/* Hero */}
        <section className="relative overflow-hidden rounded-[28px] bg-gradient-to-br from-blue-700 via-indigo-700 to-violet-700 p-6 text-white shadow-2xl shadow-blue-900/20 sm:p-8">
          <div className="absolute -right-20 -top-24 h-72 w-72 rounded-full bg-white/10 blur-2xl" />
          <div className="absolute -bottom-28 left-1/3 h-64 w-64 rounded-full bg-cyan-300/10 blur-3xl" />
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(255,255,255,0.18),transparent_38%)]" />

          <div className="relative flex flex-col gap-6 xl:flex-row xl:items-end xl:justify-between">
            <div>
              <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-xs font-semibold backdrop-blur">
                <ShieldCheck className="h-4 w-4" />
                Administration workspace
              </div>

              <h1 className="max-w-3xl text-3xl font-black tracking-tight sm:text-4xl lg:text-5xl">
                School management at a glance
              </h1>

              <p className="mt-3 max-w-2xl text-sm leading-6 text-blue-100 sm:text-base">
                Monitor users, classes, courses, attendance, and school activity
                from one central dashboard.
              </p>

              <div className="mt-5 flex flex-wrap items-center gap-3 text-xs text-blue-100 sm:text-sm">
                <span className="inline-flex items-center gap-2 rounded-full bg-black/10 px-3 py-2 backdrop-blur">
                  <CalendarDays className="h-4 w-4" />
                  {formattedDate}
                </span>

                <span className="inline-flex items-center gap-2 rounded-full bg-black/10 px-3 py-2 backdrop-blur">
                  <Activity className="h-4 w-4" />
                  Live administrative overview
                </span>
              </div>
            </div>

            <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
              <div className="flex rounded-2xl border border-white/20 bg-white/10 p-1 backdrop-blur">
                {RANGE_OPTIONS.map((option) => (
                  <button
                    key={option.value}
                    type="button"
                    onClick={() => setTimeRange(option.value)}
                    className={`rounded-xl px-4 py-2 text-sm font-semibold transition ${
                      timeRange === option.value
                        ? "bg-white text-indigo-700 shadow-lg"
                        : "text-white/80 hover:bg-white/10 hover:text-white"
                    }`}
                  >
                    {option.label}
                  </button>
                ))}
              </div>

              <button
                type="button"
                onClick={() => fetchDashboardData({ silent: true })}
                disabled={refreshing}
                className="inline-flex h-11 items-center justify-center gap-2 rounded-xl border border-white/20 bg-white/10 px-4 text-sm font-semibold backdrop-blur transition hover:bg-white/20 disabled:cursor-not-allowed disabled:opacity-60"
              >
                <RefreshCw
                  className={`h-4 w-4 ${refreshing ? "animate-spin" : ""}`}
                />
                Refresh
              </button>
            </div>
          </div>
        </section>

        {/* Additional administration metrics */}
        <section className="grid grid-cols-1 gap-4 md:grid-cols-2">
          {SUMMARY_ITEMS.map((item) => {
            const Icon = item.icon;
            const value = Number(summary[item.key]) || 0;

            return (
              <article
                key={item.key}
                className={`group relative overflow-hidden rounded-3xl border p-5 shadow-lg transition duration-300 hover:-translate-y-1 hover:shadow-xl ${panelClass}`}
              >
                <div
                  className={`absolute -right-10 -top-10 h-32 w-32 rounded-full ${item.surface} blur-2xl`}
                />

                <div className="relative flex items-center gap-4">
                  <div
                    className={`flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl ${item.surface}`}
                  >
                    <Icon className={`h-7 w-7 ${item.accent}`} />
                  </div>

                  <div className="min-w-0 flex-1">
                    <p className="text-3xl font-black tracking-tight">
                      {value}
                    </p>

                    <p className="mt-1 text-sm font-bold">
                      {item.label}
                    </p>

                    <p className={`mt-1 text-xs ${mutedText}`}>
                      {item.description}
                    </p>
                  </div>

                  <BarChart3 className={`h-5 w-5 shrink-0 ${mutedText}`} />
                </div>
              </article>
            );
          })}
        </section>

        {/* Main statistics */}
        <section className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {stats.length > 0 ? (
            stats.map((stat, index) => {
              const Icon = STAT_ICONS[stat?.title] || BarChart3;

              return (
                <article
                  key={stat?.title || index}
                  className={`group relative overflow-hidden rounded-3xl border p-5 shadow-lg transition duration-300 hover:-translate-y-1 hover:shadow-xl ${panelClass}`}
                >
                  <div
                    className={`absolute inset-x-0 top-0 h-1 bg-gradient-to-r ${
                      stat?.color || "from-blue-500 to-violet-500"
                    }`}
                  />

                  <div
                    className={`absolute -right-10 -top-10 h-32 w-32 rounded-full bg-gradient-to-br ${
                      stat?.color || "from-blue-500 to-violet-500"
                    } opacity-[0.08] blur-2xl`}
                  />

                  <div className="relative">
                    <div className="flex items-start justify-between gap-4">
                      <div
                        className={`flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br ${
                          stat?.color || "from-blue-500 to-violet-500"
                        } shadow-lg`}
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

                    <p className={`mt-1 text-sm font-medium ${mutedText}`}>
                      {stat?.title || "Statistic"}
                    </p>

                    <div className={`mt-5 h-1.5 overflow-hidden rounded-full ${progressTrack}`}>
                      <div
                        className={`h-full rounded-full bg-gradient-to-r ${
                          stat?.color || "from-blue-500 to-violet-500"
                        }`}
                        style={{
                          width:
                            stat?.title === "Attendance Rate"
                              ? `${Math.min(
                                  100,
                                  Number.parseFloat(stat?.value) || 0
                                )}%`
                              : "68%",
                        }}
                      />
                    </div>
                  </div>
                </article>
              );
            })
          ) : (
            <EmptyPanel
              className="sm:col-span-2 xl:col-span-4"
              panelClass={panelClass}
              mutedText={mutedText}
              icon={BarChart3}
              title="No statistics available"
              text="Statistics will appear here once the backend returns data."
            />
          )}
        </section>

        {/* Charts */}
        <section className="grid grid-cols-1 gap-6 xl:grid-cols-[minmax(0,1.65fr)_minmax(340px,0.85fr)]">
          <article className={`rounded-3xl border p-5 shadow-lg sm:p-6 ${panelClass}`}>
            <PanelHeader
              icon={BarChart3}
              title="Enrollment overview"
              subtitle="Current distribution between students and teachers"
              mutedText={mutedText}
              badge={timeRange}
            />

            {normalizedEnrollmentData.length > 0 ? (
              <div className="mt-7">
                <div
                  className={`relative h-72 overflow-hidden rounded-2xl border p-5 ${
                    isDark
                      ? "border-slate-800 bg-slate-950/50"
                      : "border-slate-100 bg-slate-50/80"
                  }`}
                >
                  <div className="pointer-events-none absolute inset-0 flex flex-col justify-between px-5 py-8 opacity-70">
                    {[100, 75, 50, 25, 0].map((value) => (
                      <div key={value} className="flex items-center gap-3">
                        <span className={`w-7 text-[10px] ${mutedText}`}>
                          {value}%
                        </span>
                        <div
                          className={`h-px flex-1 ${
                            isDark ? "bg-slate-800" : "bg-slate-200"
                          }`}
                        />
                      </div>
                    ))}
                  </div>

                  <div className="relative z-10 flex h-full items-end justify-center gap-10 pl-10 sm:gap-16">
                    {normalizedEnrollmentData.map((data, index) => {
                      const height =
                        data.count > 0
                          ? Math.max((data.count / maxCount) * 100, 10)
                          : 3;

                      const isStudent =
                        String(data?.category || "").toLowerCase() ===
                        "students";

                      const color = isStudent
                        ? "from-blue-600 via-blue-500 to-cyan-400"
                        : "from-violet-600 via-purple-500 to-fuchsia-400";

                      return (
                        <div
                          key={data?.category || index}
                          className="flex h-full min-w-[90px] flex-col items-center justify-end"
                        >
                          <div className="group relative flex h-[210px] w-20 items-end">
                            <div
                              className={`relative w-full rounded-t-2xl bg-gradient-to-t ${color} shadow-xl transition duration-500 group-hover:brightness-110`}
                              style={{ height: `${height}%` }}
                            >
                              <span className="absolute -top-9 left-1/2 -translate-x-1/2 rounded-lg bg-slate-950 px-2.5 py-1 text-xs font-bold text-white opacity-0 shadow-lg transition group-hover:opacity-100">
                                {data.count}
                              </span>

                              <div className="absolute inset-x-2 top-2 h-4 rounded-full bg-white/20 blur-sm" />
                            </div>
                          </div>

                          <p className="mt-3 text-sm font-bold">
                            {data?.category || "Category"}
                          </p>

                          <p className={`mt-1 text-xs ${mutedText}`}>
                            {data.count} registered
                          </p>
                        </div>
                      );
                    })}
                  </div>
                </div>

                <div className="mt-5 grid grid-cols-2 gap-3">
                  {normalizedEnrollmentData.map((item) => (
                    <div
                      key={item.category}
                      className={`rounded-2xl p-4 ${softSurface}`}
                    >
                      <p className={`text-xs font-medium ${mutedText}`}>
                        {item.category}
                      </p>

                      <div className="mt-2 flex items-end justify-between gap-3">
                        <p className="text-2xl font-black">{item.count}</p>
                        <span className="text-xs font-bold text-emerald-600">
                          Active
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ) : (
              <EmptyState
                icon={Users}
                title="No enrollment data"
                text="Student and teacher totals will be displayed here."
                mutedText={mutedText}
              />
            )}
          </article>

          <article className={`rounded-3xl border p-5 shadow-lg sm:p-6 ${panelClass}`}>
            <PanelHeader
              icon={Users}
              title="Gender distribution"
              subtitle="Student demographic breakdown"
              mutedText={mutedText}
            />

            <div className="mt-7 flex justify-center">
              <div className="relative h-64 w-64">
                <svg
                  viewBox="0 0 224 224"
                  className="h-full w-full -rotate-90"
                  role="img"
                  aria-label="Gender distribution chart"
                >
                  <circle
                    cx="112"
                    cy="112"
                    r="88"
                    fill="none"
                    stroke={isDark ? "#1e293b" : "#e2e8f0"}
                    strokeWidth="22"
                  />

                  {maleDash > 0 && (
                    <circle
                      cx="112"
                      cy="112"
                      r="88"
                      fill="none"
                      stroke="#2563eb"
                      strokeWidth="22"
                      strokeDasharray={`${maleDash} ${circumference}`}
                      strokeDashoffset="0"
                      strokeLinecap="round"
                      className="transition-all duration-1000"
                    />
                  )}

                  {femaleDash > 0 && (
                    <circle
                      cx="112"
                      cy="112"
                      r="88"
                      fill="none"
                      stroke="#ec4899"
                      strokeWidth="22"
                      strokeDasharray={`${femaleDash} ${circumference}`}
                      strokeDashoffset={-maleDash}
                      strokeLinecap="round"
                      className="transition-all duration-1000"
                    />
                  )}
                </svg>

                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="text-center">
                    <p className="text-4xl font-black">{totalStudents}</p>
                    <p className={`mt-1 text-xs font-semibold ${mutedText}`}>
                      Total students
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <div className="mt-4 grid grid-cols-2 gap-3">
              <GenderCard
                icon={Users}
                label="Male"
                percentage={genderData.male}
                count={genderData.maleCount}
                color="blue"
                isDark={isDark}
              />

              <GenderCard
                icon={Users}
                label="Female"
                percentage={genderData.female}
                count={genderData.femaleCount}
                color="pink"
                isDark={isDark}
              />
            </div>
          </article>
        </section>

        {/* Performance, attendance, announcements */}
        <section className="grid grid-cols-1 gap-6 xl:grid-cols-3">
          <MetricListCard
            panelClass={panelClass}
            mutedText={mutedText}
            progressTrack={progressTrack}
            icon={TrendingUp}
            title="Class performance"
            subtitle="Average grades by class"
            data={classPerformanceData}
            valueKey="average"
            fallbackColor="#2563eb"
            emptyTitle="No performance data"
          />

          <MetricListCard
            panelClass={panelClass}
            mutedText={mutedText}
            progressTrack={progressTrack}
            icon={Activity}
            title="Class attendance"
            subtitle="Attendance rates by class"
            data={classAttendanceData}
            valueKey="attendance"
            fallbackColor="#10b981"
            emptyTitle="No attendance data"
          />

          <article className={`rounded-3xl border p-5 shadow-lg sm:p-6 ${panelClass}`}>
            <PanelHeader
              icon={Megaphone}
              title="Announcements"
              subtitle="Latest school updates"
              mutedText={mutedText}
              badge={`${announcements.length} new`}
            />

            <div className="mt-5 max-h-[360px] space-y-3 overflow-y-auto pr-1">
              {announcements.length > 0 ? (
                announcements.slice(0, 5).map((announcement, index) => (
                  <div
                    key={announcement?._id || announcement?.title || index}
                    className={`group rounded-2xl border p-4 transition hover:-translate-y-0.5 ${
                      isDark
                        ? "border-slate-800 bg-slate-800/50 hover:bg-slate-800"
                        : "border-slate-100 bg-slate-50 hover:bg-white hover:shadow-md"
                    }`}
                  >
                    <div className="flex items-start gap-3">
                      <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-amber-500/10 text-xl">
                        {announcement?.icon || "📢"}
                      </div>

                      <div className="min-w-0 flex-1">
                        <h3 className="truncate text-sm font-bold">
                          {announcement?.title || "Announcement"}
                        </h3>

                        <p className={`mt-1 line-clamp-2 text-xs leading-5 ${mutedText}`}>
                          {announcement?.description || "No description"}
                        </p>

                        <div className={`mt-3 flex items-center gap-1.5 text-[11px] ${mutedText}`}>
                          <Clock3 className="h-3.5 w-3.5" />
                          {announcement?.date || "Recently"}
                        </div>
                      </div>
                    </div>
                  </div>
                ))
              ) : (
                <EmptyState
                  icon={Megaphone}
                  title="No announcements"
                  text="Recent announcements will appear here."
                  mutedText={mutedText}
                />
              )}
            </div>
          </article>
        </section>

        {/* Activity */}
        <section className={`rounded-3xl border p-5 shadow-lg sm:p-6 ${panelClass}`}>
          <PanelHeader
            icon={Clock3}
            title="Recent system activity"
            subtitle="Latest registrations and administrative updates"
            mutedText={mutedText}
            badge={`${recentActivity.length} events`}
          />

          {recentActivity.length > 0 ? (
            <div className="mt-6 grid grid-cols-1 gap-3 lg:grid-cols-2">
              {recentActivity.slice(0, 8).map((activity, index) => (
                <div
                  key={activity?._id || `${activity?.action}-${index}`}
                  className={`group flex items-center gap-4 rounded-2xl border p-4 transition hover:-translate-y-0.5 ${
                    isDark
                      ? "border-slate-800 bg-slate-800/45 hover:bg-slate-800"
                      : "border-slate-100 bg-slate-50 hover:bg-white hover:shadow-md"
                  }`}
                >
                  <div
                    className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br ${
                      activity?.color || "from-blue-500 to-violet-500"
                    } text-xl shadow-lg`}
                  >
                    {activity?.icon || "⚙️"}
                  </div>

                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-bold">
                      {activity?.action || "System activity"}
                    </p>

                    <p className={`mt-1 truncate text-xs ${mutedText}`}>
                      {activity?.user || "System"}
                    </p>
                  </div>

                  <span
                    className={`shrink-0 rounded-full px-2.5 py-1 text-[11px] font-semibold ${
                      isDark
                        ? "bg-slate-700 text-slate-300"
                        : "bg-white text-slate-500 shadow-sm"
                    }`}
                  >
                    {activity?.time || "Now"}
                  </span>
                </div>
              ))}
            </div>
          ) : (
            <EmptyState
              icon={Clock3}
              title="No recent activity"
              text="New system events will appear here."
              mutedText={mutedText}
            />
          )}
        </section>
      </div>
    </main>
  );
}

function PanelHeader({
  icon: Icon,
  title,
  subtitle,
  mutedText,
  badge,
}) {
  return (
    <div className="flex items-start justify-between gap-4">
      <div className="flex items-start gap-3">
        <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-600 to-violet-600 shadow-lg shadow-blue-500/15">
          <Icon className="h-5 w-5 text-white" />
        </div>

        <div>
          <h2 className="text-lg font-black">{title}</h2>
          <p className={`mt-1 text-xs ${mutedText}`}>{subtitle}</p>
        </div>
      </div>

      {badge && (
        <span className="rounded-full bg-blue-500/10 px-3 py-1 text-[11px] font-bold capitalize text-blue-600">
          {badge}
        </span>
      )}
    </div>
  );
}

function GenderCard({
  icon: Icon,
  label,
  percentage,
  count,
  color,
  isDark,
}) {
  const styles =
    color === "pink"
      ? {
          box: isDark
            ? "border-pink-500/20 bg-pink-500/10"
            : "border-pink-100 bg-pink-50",
          icon: "bg-pink-500/10 text-pink-600",
          value: "text-pink-600",
        }
      : {
          box: isDark
            ? "border-blue-500/20 bg-blue-500/10"
            : "border-blue-100 bg-blue-50",
          icon: "bg-blue-500/10 text-blue-600",
          value: "text-blue-600",
        };

  return (
    <div className={`rounded-2xl border p-4 ${styles.box}`}>
      <div className="flex items-center justify-between">
        <div className={`flex h-9 w-9 items-center justify-center rounded-xl ${styles.icon}`}>
          <Icon className="h-4 w-4" />
        </div>

        <span className={`text-xl font-black ${styles.value}`}>
          {Number(percentage).toFixed(1)}%
        </span>
      </div>

      <p className="mt-4 text-sm font-bold">{label}</p>
      <p className="mt-1 text-xs opacity-70">{count} students</p>
    </div>
  );
}

function MetricListCard({
  panelClass,
  mutedText,
  progressTrack,
  icon,
  title,
  subtitle,
  data,
  valueKey,
  fallbackColor,
  emptyTitle,
}) {
  return (
    <article className={`rounded-3xl border p-5 shadow-lg sm:p-6 ${panelClass}`}>
      <PanelHeader
        icon={icon}
        title={title}
        subtitle={subtitle}
        mutedText={mutedText}
      />

      <div className="mt-6 max-h-[360px] space-y-5 overflow-y-auto pr-1">
        {data.length > 0 ? (
          data.map((item, index) => {
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

                    <p className={`mt-0.5 text-[11px] ${mutedText}`}>
                      {value >= 80
                        ? "Excellent"
                        : value >= 60
                        ? "Good"
                        : "Needs attention"}
                    </p>
                  </div>

                  <span className="rounded-full bg-blue-500/10 px-2.5 py-1 text-xs font-black text-blue-600">
                    {value}%
                  </span>
                </div>

                <div className={`h-2.5 overflow-hidden rounded-full ${progressTrack}`}>
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
          })
        ) : (
          <EmptyState
            icon={icon}
            title={emptyTitle}
            text="This information will appear when data becomes available."
            mutedText={mutedText}
          />
        )}
      </div>
    </article>
  );
}

function EmptyPanel({
  className = "",
  panelClass,
  mutedText,
  icon: Icon,
  title,
  text,
}) {
  return (
    <div
      className={`rounded-3xl border p-8 text-center shadow-lg ${panelClass} ${className}`}
    >
      <Icon className={`mx-auto h-10 w-10 ${mutedText}`} />
      <p className="mt-4 font-bold">{title}</p>
      <p className={`mt-1 text-sm ${mutedText}`}>{text}</p>
    </div>
  );
}

function EmptyState({
  icon: Icon,
  title,
  text,
  mutedText,
}) {
  return (
    <div className="flex min-h-40 flex-col items-center justify-center rounded-2xl border border-dashed border-slate-300/40 p-6 text-center">
      <Icon className={`h-9 w-9 ${mutedText}`} />
      <p className="mt-3 text-sm font-bold">{title}</p>
      <p className={`mt-1 max-w-xs text-xs leading-5 ${mutedText}`}>
        {text}
      </p>
    </div>
  );
}
