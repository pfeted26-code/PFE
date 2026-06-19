import React, { useState, useEffect } from "react";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { FileText, Calendar, Award, TrendingUp, Clock, MapPin, Filter, Loader2 } from "lucide-react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { getAllExamen } from "@/services/examenService";
import { getNotesForStudent } from "@/services/noteService";

const Exams = () => {
  const [filterStatus, setFilterStatus] = useState("all");
  const [exams, setExams] = useState([]);
  const [notes, setNotes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const [examsResponse, notesResponse] = await Promise.all([
          getAllExamen(),
          getNotesForStudent()
        ]);

        const examsData = examsResponse.data;
        const notesData = notesResponse.data;

        // Process exams data
        const processedExams = examsData.map((exam, index) => {
          const note = notesData.find(n => n.examen._id === exam._id);
          const now = new Date();
          const examDate = new Date(exam.date);
          const isCompleted = examDate < now || note;

          const colors = [
            "from-primary to-primary-light",
            "from-secondary to-accent",
            "from-accent to-secondary",
            "from-primary to-secondary",
            "from-secondary to-primary"
          ];

          return {
            ...exam,
            course: exam.nom || "Unknown Exam",
            courseName: exam.coursId?.nom || exam.cours?.nom || exam.nom || "Unknown Course",
            code: exam.type || "N/A",
            className: exam.classeId?.nom || "Unknown Class",

            status: isCompleted ? "Completed" : "Upcoming",
            grade: note ? calculateGrade(note.score, exam.noteMax) : null,
            score: note ? note.score : null,
            noteMax: exam.noteMax,
            feedback: note ? note.feedback || note.commentaire : null,
            color: colors[index % colors.length]
          };
        });

        setExams(processedExams);
        setNotes(notesData);
      } catch (err) {
        console.error("Error fetching data:", err);
        setError("Failed to load exams and grades. Please try again.");
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  // Calculate stats from data
  const stats = React.useMemo(() => {
    const completedExams = exams.filter(e => e.status === "Completed");
    const upcomingExams = exams.filter(e => e.status === "Upcoming");
    const scores = completedExams.map(e => e.score).filter(s => s != null);

    const averageScore = scores.length > 0 ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length) : 0;
    const gpa = scores.length > 0 ? (averageScore / 25).toFixed(2) : "0.00"; // Rough GPA calculation

    return [
      { label: "Current GPA", value: gpa, icon: Award, color: "from-accent to-secondary" },
      { label: "Average Score", value: `${averageScore}%`, icon: TrendingUp, color: "from-primary to-accent" },
      { label: "Exams Taken", value: completedExams.length.toString(), icon: FileText, color: "from-secondary to-primary" },
      { label: "Upcoming", value: upcomingExams.length.toString(), icon: Calendar, color: "from-accent to-primary" },
    ];
  }, [exams]);

  const filteredExams = filterStatus === "all"
    ? exams
    : exams.filter(e => e.status.toLowerCase() === filterStatus);

  // Helper function to calculate grade
  const calculateGrade = (score, maxScore) => {
    const percentage = (score / maxScore) * 100;

    if (percentage >= 90) return "A";
    if (percentage >= 80) return "B";
    if (percentage >= 70) return "C";
    if (percentage >= 60) return "D";
    return "F";
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-background via-background to-accent/5 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin mx-auto mb-4" />
          <p className="text-muted-foreground">Loading exams and grades...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-background via-background to-accent/5 flex items-center justify-center">
        <div className="text-center">
          <p className="text-red-500 mb-4">{error}</p>
          <Button onClick={() => window.location.reload()}>
            Try Again
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-accent/5">
      <div className="container mx-auto p-6 md:p-8">
        <div className="mb-8 animate-fade-in">
          <h1 className="text-4xl md:text-5xl font-bold mb-3 bg-gradient-to-r from-primary via-secondary to-accent bg-clip-text text-transparent">
            Exams & Grades
          </h1>
          <p className="text-muted-foreground text-lg">
            Track your exam schedule and academic performance
          </p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8 animate-fade-in-up">
          {stats.map((stat, index) => {
            const Icon = stat.icon;
            return (
              <Card
                key={index}
                style={{ animationDelay: `${index * 0.1}s` }}
                className="group p-6 hover:shadow-2xl transition-all duration-300 hover:-translate-y-1 border-none overflow-hidden relative animate-scale-in"
              >
                <div className={`absolute inset-0 bg-gradient-to-br ${stat.color} opacity-5 group-hover:opacity-10 transition-opacity`} />

                <div className="relative z-10">
                  <div className={`h-10 w-10 rounded-xl bg-gradient-to-br ${stat.color} flex items-center justify-center mb-3 group-hover:scale-110 transition-transform shadow-lg`}>
                    <Icon className="h-5 w-5 text-white" />
                  </div>
                  <div className="text-3xl font-bold mb-1">{stat.value}</div>
                  <div className="text-sm text-muted-foreground">{stat.label}</div>
                </div>
              </Card>
            );
          })}
        </div>

        {/* Filter Tabs */}
        <Tabs value={filterStatus} onValueChange={setFilterStatus} className="mb-6">
          <TabsList className="grid w-full md:w-auto grid-cols-3 h-12">
            <TabsTrigger value="all" className="gap-2">
              <Filter className="h-4 w-4" />
              All Exams
            </TabsTrigger>
            <TabsTrigger value="upcoming">Upcoming</TabsTrigger>
            <TabsTrigger value="completed">Completed</TabsTrigger>
          </TabsList>
        </Tabs>

        {/* Exams List */}
        <div className="space-y-4">
          {filteredExams.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-muted-foreground">No exams found for the selected filter.</p>
            </div>
          ) : (
            filteredExams.map((exam, index) => (
              <Card
                key={exam._id}
                style={{ animationDelay: `${index * 0.1}s` }}
                className="group p-6 hover:shadow-2xl transition-all duration-300 hover:-translate-y-1 animate-scale-in border-none overflow-hidden relative"
              >
                <div className={`absolute inset-0 bg-gradient-to-br ${exam.color} opacity-5 group-hover:opacity-10 transition-opacity`} />

                <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-4">
                  <div className="flex items-start gap-4 flex-1">
                    <div className={`h-14 w-14 rounded-2xl bg-gradient-to-br ${exam.color} flex items-center justify-center group-hover:scale-110 transition-transform flex-shrink-0 shadow-lg`}>
                      <FileText className="h-7 w-7 text-white" />
                    </div>

                    <div className="flex-1">
                      <h3 className="text-xl font-bold mb-2 group-hover:text-primary transition-colors">
                        {exam.course}
                      </h3>
                      <p className="text-sm font-medium text-muted-foreground mb-3">
                        {exam.className}
                      </p>

                      <div className="flex flex-wrap items-center gap-2 mb-3">
                        <Badge variant="outline" className="font-mono">{exam.code}</Badge>
                        <Badge variant="secondary">{exam.type}</Badge>
                        <Badge
                          className={exam.status === "Completed" ? "bg-accent text-white" : "bg-muted"}
                        >
                          {exam.status}
                        </Badge>
                      </div>
                      <div className="flex flex-wrap gap-4 text-sm text-muted-foreground">
                        <div className="flex items-center gap-1">
                          <Calendar className="h-4 w-4" />
                          <span>{new Date(exam.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}</span>
                        </div>
                        {exam.description && (
                          <div className="flex items-center gap-1">
                            <FileText className="h-4 w-4" />
                            <span>{exam.description}</span>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>

                  {exam.status === "Completed" && exam.grade && (
                    <div className={`mt-4 p-3 rounded-lg border ${
                      exam.score >= 14
                        ? "bg-green-50 border-green-200"
                        : exam.score >= 10
                        ? "bg-yellow-50 border-yellow-200"
                        : "bg-red-50 border-red-200"
                    }`}>
                      <p className={`text-sm font-semibold ${
                        exam.score >= 14
                          ? "text-green-800"
                          : exam.score >= 10
                          ? "text-yellow-800"
                          : "text-red-800"
                      }`}>
                        Your Grade: {exam.score}/{exam.noteMax}
                      </p>
                      {exam.feedback && (
                        <p className={`text-sm mt-1 ${
                          exam.score >= 14
                            ? "text-green-700"
                            : exam.score >= 10
                            ? "text-yellow-700"
                            : "text-red-700"
                        }`}>
                          {exam.feedback}
                        </p>
                      )}
                    </div>
                  )}

                  {exam.status === "Upcoming" && (
                    <Button className="bg-gradient-to-r from-primary via-secondary to-accent hover:opacity-90">
                      Study Now
                    </Button>
                  )}
                </div>
              </Card>
            ))
          )}
        </div>
      </div>
    </div>
  );
};

export default Exams;
