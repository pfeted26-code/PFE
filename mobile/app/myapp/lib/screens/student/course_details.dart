import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IMPORTANT
// Android emulator: use http://10.0.2.2:5000
// Real phone: replace with your laptop IP, example http://192.168.1.211:5000
// ─────────────────────────────────────────────────────────────────────────────

const String kBaseUrl = 'http://192.168.1.211:5000';

// ─────────────────────────────────────────────────────────────────────────────
// Dark React-style colors
// ─────────────────────────────────────────────────────────────────────────────

const Color _bg = Color(0xFF0F1117);
const Color _card = Color(0xFF121826);
const Color _card2 = Color(0xFF171D2B);
const Color _border = Color(0xFF2A2D3A);
const Color _primary = Color(0xFF6366F1);
const Color _secondary = Color(0xFF8B5CF6);
const Color _text = Color(0xFFE2E8F0);
const Color _muted = Color(0xFF94A3B8);
const Color _green = Color(0xFF10B981);
const Color _amber = Color(0xFFF59E0B);
const Color _red = Color(0xFFEF4444);
const Color _blue = Color(0xFF3B82F6);

// ─────────────────────────────────────────────────────────────────────────────
// API service for this page
// ─────────────────────────────────────────────────────────────────────────────

class _CourseDetailsApi {
  final String? token;

  _CourseDetailsApi({this.token});

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getCourseById(String id) async {
    final uri = Uri.parse('$kBaseUrl/cours/getCoursById/$id');
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to load course');
    }

    final decoded = jsonDecode(res.body);

    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded['data']);
      }
      return decoded;
    }

    throw Exception('Invalid course response');
  }

  Future<List<dynamic>> getMaterialsByCourse(String courseId) async {
    // Backend route: /course-material/course/:coursId
    final possibleUrls = [
      '$kBaseUrl/course-material/course/$courseId',
      // Fallbacks (kept for compatibility if backend changes)
      '$kBaseUrl/course-materials/course/$courseId',
      '$kBaseUrl/materials/course/$courseId',
      '$kBaseUrl/courseMaterials/getMaterialsByCourse/$courseId',
    ];


    for (final url in possibleUrls) {
      try {
        final res = await http.get(Uri.parse(url), headers: _headers);

        if (res.statusCode >= 200 && res.statusCode < 300) {
          final decoded = jsonDecode(res.body);

          if (decoded is List) return decoded;
          if (decoded is Map<String, dynamic> && decoded['data'] is List) {
            return decoded['data'];
          }
          if (decoded is Map<String, dynamic> && decoded['materials'] is List) {
            return decoded['materials'];
          }
        }
      } catch (_) {}
    }

    return [];
  }

  Future<Map<String, dynamic>?> getNoteByExamAndStudent({
    required String examId,
    required String? userId,
  }) async {
    if (userId == null || userId.isEmpty) return null;

    final possibleUrls = [
      '$kBaseUrl/notes/getNoteByExamenAndEtudiant/$examId/$userId',
      '$kBaseUrl/note/getNoteByExamenAndEtudiant/$examId/$userId',
    ];

    for (final url in possibleUrls) {
      try {
        final res = await http.get(Uri.parse(url), headers: _headers);

        if (res.statusCode >= 200 && res.statusCode < 300) {
          final decoded = jsonDecode(res.body);

          if (decoded is Map<String, dynamic>) {
            if (decoded['data'] is Map<String, dynamic>) {
              return Map<String, dynamic>.from(decoded['data']);
            }
            return decoded;
          }
        }
      } catch (_) {}
    }

    return null;
  }

  Future<void> submitAssignment({
    required String assignmentId,
    required PlatformFile file,
  }) async {
    await _sendAssignmentFile(
      endpoint: '$kBaseUrl/examens/submitAssignment/$assignmentId',
      assignmentId: assignmentId,
      file: file,
    );
  }

  Future<void> replaceSubmission({
    required String assignmentId,
    required PlatformFile file,
  }) async {
    await _sendAssignmentFile(
      endpoint: '$kBaseUrl/examens/updateSubmission/$assignmentId',
      assignmentId: assignmentId,
      file: file,
      method: 'PUT',
    );
  }

  Future<void> deleteSubmission(String assignmentId) async {
    final possibleUrls = [
      '$kBaseUrl/examens/deleteSubmission/$assignmentId',
      '$kBaseUrl/examen/deleteSubmission/$assignmentId',
    ];

    for (final url in possibleUrls) {
      final res = await http.delete(Uri.parse(url), headers: _headers);

      if (res.statusCode >= 200 && res.statusCode < 300) return;
    }

    throw Exception('Failed to delete submission');
  }

  Future<void> _sendAssignmentFile({
    required String endpoint,
    required String assignmentId,
    required PlatformFile file,
    String method = 'POST',
  }) async {
    if (file.path == null) {
      throw Exception('Invalid selected file');
    }

    final request = http.MultipartRequest(method, Uri.parse(endpoint));

    if (token != null && token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path!,
        filename: file.name,
      ),
    );

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Assignment upload failed';

      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'].toString();
        }
      } catch (_) {}

      throw Exception(msg);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Page
// ─────────────────────────────────────────────────────────────────────────────

class StudentCourseDetailsScreen extends StatefulWidget {
  final String courseId;
  final String? token;
  final String? userId;

  const StudentCourseDetailsScreen({
    super.key,
    required this.courseId,
    this.token,
    this.userId,
  });

  @override
  State<StudentCourseDetailsScreen> createState() =>
      _StudentCourseDetailsScreenState();
}

class _StudentCourseDetailsScreenState
    extends State<StudentCourseDetailsScreen> {
  late final _CourseDetailsApi _api;

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _course;
  List<dynamic> _materials = [];
  List<dynamic> _assignments = [];
  List<dynamic> _exams = [];

  final Map<String, Map<String, dynamic>> _notesMap = {};
  final Map<String, Map<String, dynamic>> _localSubmissionMap = {};
  final Map<String, PlatformFile> _selectedFileMap = {};

  String _activeTab = 'chapters';

  String? _submittingId;
  String? _replacingId;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    _api = _CourseDetailsApi(token: widget.token);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final course = await _api.getCourseById(widget.courseId);
      final materials = await _api.getMaterialsByCourse(widget.courseId);

      final allExams = _asList(course['examens'] ?? course['exams']);

      final assignments = allExams.where((item) {
        final type = _str(item['type']).toLowerCase();
        return type == 'assignment';
      }).toList();

      final exams = allExams.where((item) {
        final type = _str(item['type']).toLowerCase();
        return type != 'assignment';
      }).toList();

      await _fetchNotesForExams(allExams);

      if (!mounted) return;

      setState(() {
        _course = course;
        _materials = materials;
        _assignments = assignments;
        _exams = exams;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchNotesForExams(List<dynamic> exams) async {
    _notesMap.clear();

    for (final exam in exams) {
      final examId = _str(exam['_id'] ?? exam['id']);

      if (examId.isEmpty) continue;

      final note = await _api.getNoteByExamAndStudent(
        examId: examId,
        userId: widget.userId,
      );

      if (note != null) {
        _notesMap[examId] = note;
      }
    }
  }

  Future<void> _pickFile(String assignmentId, {bool replace = false}) async {
final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'zip', 'rar'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (file.size > 10 * 1024 * 1024) {
      _showSnack('File size must be less than 10MB', error: true);
      return;
    }

    setState(() {
      _selectedFileMap[assignmentId] = file;
    });

    if (replace) {
      await _replaceSubmission(assignmentId);
    }
  }

  Future<void> _submitAssignment(String assignmentId) async {
    final file = _selectedFileMap[assignmentId];

    if (file == null) {
      _showSnack('Please select a file first', error: true);
      return;
    }

    setState(() => _submittingId = assignmentId);

    try {
      await _api.submitAssignment(assignmentId: assignmentId, file: file);

      _showSnack('Assignment submitted successfully');

      setState(() {
        _selectedFileMap.remove(assignmentId);
        _localSubmissionMap[assignmentId] = {
          'submitted': true,
          'data': {
            'dateSubmission': DateTime.now().toIso8601String(),
            'fileName': file.name,
            'note': null,
            'commentaire': null,
          },
        };
      });

      await _fetchData();
    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _submittingId = null);
    }
  }

  Future<void> _replaceSubmission(String assignmentId) async {
    final file = _selectedFileMap[assignmentId];

    if (file == null) {
      _showSnack('Please select a file first', error: true);
      return;
    }

    setState(() => _replacingId = assignmentId);

    try {
      await _api.replaceSubmission(assignmentId: assignmentId, file: file);

      _showSnack('Submission updated successfully');

      setState(() {
        _selectedFileMap.remove(assignmentId);
        _localSubmissionMap[assignmentId] = {
          'submitted': true,
          'data': {
            'dateSubmission': DateTime.now().toIso8601String(),
            'fileName': file.name,
            'note': null,
            'commentaire': null,
          },
        };
      });

      await _fetchData();
    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _replacingId = null);
    }
  }

  Future<void> _deleteSubmission(String assignmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: _card,
          title: const Text(
            'Delete submission?',
            style: TextStyle(color: _text),
          ),
          content: const Text(
            'This action cannot be undone.',
            style: TextStyle(color: _muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: _red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _deletingId = assignmentId);

    try {
      await _api.deleteSubmission(assignmentId);

      _showSnack('Submission deleted successfully');

      setState(() {
        _localSubmissionMap.remove(assignmentId);
      });

      await _fetchData();
    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Map<String, dynamic> _submissionStatus(dynamic assignment) {
    final assignmentId = _str(assignment['_id'] ?? assignment['id']);

    if (_localSubmissionMap.containsKey(assignmentId)) {
      return _localSubmissionMap[assignmentId]!;
    }

    final submissions = _asList(assignment['submissions']);

    for (final sub in submissions) {
      final subUserId = _str(sub['studentId'] ?? sub['etudiant']);

      if (subUserId == _str(widget.userId)) {
        final data = Map<String, dynamic>.from(sub);

        final note = _notesMap[assignmentId];
        if (note != null) {
          data['note'] = note['score'] ?? note['note'] ?? data['note'];
          data['commentaire'] =
              note['commentaire'] ?? note['feedback'] ?? data['commentaire'];
        }

        return {
          'submitted': true,
          'data': data,
        };
      }
    }

    final note = _notesMap[assignmentId];

    if (note != null) {
      return {
        'submitted': true,
        'data': {
          'note': note['score'] ?? note['note'],
          'commentaire': note['commentaire'] ?? note['feedback'],
          'dateSubmission':
              note['createdAt'] ?? note['updatedAt'] ?? DateTime.now().toIso8601String(),
        },
      };
    }

    return {
      'submitted': false,
      'data': null,
    };
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: error ? _red : _green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: _EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Failed to Load Course',
            subtitle: _error!,
            buttonText: 'Try Again',
            onPressed: _fetchData,
          ),
        ),
      );
    }

    if (_course == null) {
      return Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: _EmptyState(
            icon: Icons.warning_amber_rounded,
            title: 'Course not found',
            subtitle: 'This course does not exist or could not be loaded.',
            buttonText: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _primary,
          onRefresh: _fetchData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _Header(course: _course!)),
              SliverToBoxAdapter(child: _TabsHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverToBoxAdapter(
                  child: _buildActiveTab(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _Header({required Map<String, dynamic> course}) {
    final title = _str(course['title'] ?? course['nom'], fallback: 'Untitled Course');

    final instructor = _instructorName(course);
    final semester = _str(course['semestre'], fallback: 'TBA');
    final className = _className(course);
    final code = _str(course['code'], fallback: 'N/A');
    final credits = _str(course['credits'], fallback: '3');
    final progress = _num(course['progress']).clamp(0, 100).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              _primary.withOpacity(0.20),
              _secondary.withOpacity(0.16),
              _primary.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 26,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: _SmallButton(
                icon: Icons.arrow_back_rounded,
                text: 'Back',
                onTap: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: _text,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _InfoMini(icon: Icons.person_rounded, text: instructor),
                _InfoMini(icon: Icons.calendar_month_rounded, text: semester),
                _InfoMini(icon: Icons.school_rounded, text: className),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(text: code, color: Colors.white),
                _Badge(text: '$credits Credits', color: Colors.white),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.12),
                color: _primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${progress.round()}% completed',
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _TabsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            _TabButton(
              active: _activeTab == 'chapters',
              icon: Icons.menu_book_rounded,
              label: 'Chapters',
              onTap: () => setState(() => _activeTab = 'chapters'),
            ),
            _TabButton(
              active: _activeTab == 'assignments',
              icon: Icons.description_rounded,
              label: 'Tasks',
              count: _assignments.length,
              onTap: () => setState(() => _activeTab = 'assignments'),
            ),
            _TabButton(
              active: _activeTab == 'exams',
              icon: Icons.warning_amber_rounded,
              label: 'Exams',
              count: _exams.length,
              onTap: () => setState(() => _activeTab = 'exams'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_activeTab == 'assignments') {
      return _AssignmentsTab();
    }

    if (_activeTab == 'exams') {
      return _ExamsTab();
    }

    return _MaterialsTab();
  }

  Widget _MaterialsTab() {
    if (_materials.isEmpty) {
      return const _EmptyCard(
        icon: Icons.menu_book_outlined,
        title: 'No materials yet.',
      );
    }

    return Column(
      children: _materials.map((m) {
        final title = _str(m['titre'] ?? m['title'], fallback: 'Untitled');
        final description = _str(
          m['description'],
          fallback: 'No description available.',
        );
        final type = _str(m['type']);
        final fileName = _str(m['fichier'] ?? m['file']);

        return _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardTitle(
                icon: Icons.menu_book_rounded,
                title: title,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: _muted, height: 1.4),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (type.isNotEmpty)
                    _Badge(text: type.toUpperCase(), color: _blue),
                  if (_str(m['uploadedAt']).isNotEmpty)
                    _Badge(
                      text: _formatDate(_str(m['uploadedAt'])),
                      color: _muted,
                    ),
                ],
              ),
              if (fileName.isNotEmpty) ...[
                const SizedBox(height: 16),
                _FullButton(
                  text: 'Download',
                  icon: Icons.download_rounded,
                  color: _secondary,
                  onTap: () async {
                    final url = Uri.parse('$kBaseUrl/materials/$fileName');
                    final ok = await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!ok && context.mounted) {
                      _showSnack('Unable to open file. Check URL: $url', error: true);
                    }
                  },
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _AssignmentsTab() {
    if (_assignments.isEmpty) {
      return const _EmptyCard(
        icon: Icons.description_outlined,
        title: 'No assignments yet.',
      );
    }

    return Column(
      children: _assignments.map((a) {
        final assignmentId = _str(a['_id'] ?? a['id']);
        final title = _str(a['nom'] ?? a['title'], fallback: 'Assignment');
        final description = _str(
          a['description'],
          fallback: 'Assignment details will be shared soon.',
        );

        final dueDate = _parseDate(a['date']);
        final now = DateTime.now();
        final submission = _submissionStatus(a);
        final submitted = submission['submitted'] == true;
        final submissionData = submission['data'];

        String status = 'Pending';
        if (submitted) {
          status = submissionData?['note'] != null ? 'Graded' : 'Submitted';
        } else if (dueDate != null && dueDate.isBefore(now)) {
          status = 'Overdue';
        }

        final selectedFile = _selectedFileMap[assignmentId];

        return _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CardTitle(
                      icon: Icons.description_rounded,
                      title: title,
                    ),
                  ),
                  _StatusPill(status: status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: _muted, height: 1.4),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(
                    text: dueDate != null ? _formatDateObj(dueDate) : 'TBA',
                    color: _primary,
                  ),
                  _Badge(
                    text: dueDate != null ? _formatTimeObj(dueDate) : 'TBA',
                    color: _secondary,
                  ),
                  _Badge(
                    text: _str(a['type'], fallback: 'Assignment'),
                    color: _blue,
                  ),
                  if (a['noteMax'] != null)
                    _Badge(text: 'Max: ${a['noteMax']}', color: _muted),
                ],
              ),
              if (submitted) ...[
                const SizedBox(height: 16),
                _SubmissionBox(
                  data: Map<String, dynamic>.from(submissionData ?? {}),
                  noteMax: a['noteMax'],
                ),
                if (submissionData?['note'] == null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _OutlineButton(
                          text: _replacingId == assignmentId
                              ? 'Replacing...'
                              : 'Replace File',
                          onTap: _replacingId == assignmentId
                              ? null
                              : () => _pickFile(assignmentId, replace: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OutlineButton(
                          text: _deletingId == assignmentId
                              ? 'Deleting...'
                              : 'Delete',
                          danger: true,
                          onTap: _deletingId == assignmentId
                              ? null
                              : () => _deleteSubmission(assignmentId),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              if (!submitted && dueDate != null && dueDate.isAfter(now)) ...[
                const SizedBox(height: 16),
                _OutlineButton(
                  text: selectedFile != null
                      ? selectedFile.name
                      : 'Choose File PDF, DOC, TXT, ZIP',
                  icon: Icons.attach_file_rounded,
                  onTap: () => _pickFile(assignmentId),
                ),
                const SizedBox(height: 10),
                _FullButton(
                  text: _submittingId == assignmentId
                      ? 'Submitting...'
                      : 'Submit Assignment',
                  icon: Icons.upload_file_rounded,
                  color: _green,
                  onTap: selectedFile == null || _submittingId == assignmentId
                      ? null
                      : () => _submitAssignment(assignmentId),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _ExamsTab() {
    if (_exams.isEmpty) {
      return const _EmptyCard(
        icon: Icons.warning_amber_outlined,
        title: 'No exams scheduled.',
      );
    }

    return Column(
      children: _exams.map((e) {
        final examId = _str(e['_id'] ?? e['id']);
        final title = _str(e['nom'] ?? e['title'], fallback: 'Exam');
        final description = _str(
          e['description'],
          fallback: 'Exam details will be shared soon.',
        );

        final examDate = _parseDate(e['date']);

        String status = 'TBA';
        if (examDate != null) {
          status = examDate.isAfter(DateTime.now()) ? 'Upcoming' : 'Completed';
        }

        final grade = _findGradeForExam(e, examId);

        return _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CardTitle(
                      icon: Icons.warning_amber_rounded,
                      title: title,
                    ),
                  ),
                  _StatusPill(status: status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: _muted, height: 1.4),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(
                    text: examDate != null ? _formatDateObj(examDate) : 'TBA',
                    color: _primary,
                  ),
                  _Badge(
                    text: examDate != null ? _formatTimeObj(examDate) : 'TBA',
                    color: _secondary,
                  ),
                  _Badge(
                    text: _str(e['type'], fallback: 'Written Exam'),
                    color: _green,
                  ),
                  if (e['duration'] != null)
                    _Badge(text: '${e['duration']} min', color: _blue),
                ],
              ),
              if (grade != null) ...[
                const SizedBox(height: 16),
                _GradeBox(grade: grade, noteMax: e['noteMax']),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic>? _findGradeForExam(dynamic exam, String examId) {
    final notes = _asList(exam['notes']);

    for (final note in notes) {
      final etudiant = note['etudiant'];
      final noteUserId = etudiant is Map ? _str(etudiant['_id']) : _str(etudiant);

      if (noteUserId == _str(widget.userId)) {
        return Map<String, dynamic>.from(note);
      }
    }

    return _notesMap[examId];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UI Components
// ─────────────────────────────────────────────────────────────────────────────

class _DarkCard extends StatelessWidget {
  final Widget child;

  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _CardTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _primary, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final realColor = color == Colors.white ? Colors.white : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: realColor.withOpacity(color == Colors.white ? 0.90 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color == Colors.white
              ? Colors.white.withOpacity(0.15)
              : realColor.withOpacity(0.25),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color == Colors.white ? const Color(0xFF111827) : realColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (status.toLowerCase()) {
      case 'submitted':
        color = _blue;
        break;
      case 'graded':
      case 'completed':
        color = _green;
        break;
      case 'overdue':
        color = _red;
        break;
      case 'upcoming':
      case 'pending':
        color = _amber;
        break;
      default:
        color = _muted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FullButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _FullButton({
    required this.text,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled ? color.withOpacity(0.35) : color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 19),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool danger;
  final VoidCallback? onTap;

  const _OutlineButton({
    required this.text,
    this.icon,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? _red : _primary;
    final disabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(disabled ? 0.04 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(disabled ? 0.25 : 0.65)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color.withOpacity(disabled ? 0.55 : 1),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _SmallButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _text, size: 16),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: _text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoMini extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoMini({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _muted, size: 17),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback onTap;

  const _TabButton({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? _primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: active ? Colors.white : _muted, size: 20),
              const SizedBox(height: 4),
              Text(
                count != null && count! > 0 ? '$label ($count)' : label,
                style: TextStyle(
                  color: active ? Colors.white : _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmissionBox extends StatelessWidget {
  final Map<String, dynamic> data;
  final dynamic noteMax;

  const _SubmissionBox({
    required this.data,
    this.noteMax,
  });

  @override
  Widget build(BuildContext context) {
    final note = data['note'];
    final date = _formatDate(_str(data['dateSubmission'] ?? data['date']));
    final fileName = _str(data['fileName'] ?? data['fichier'] ?? data['file']);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: _green, size: 20),
              SizedBox(width: 8),
              Text(
                'Submitted',
                style: TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Submitted on $date',
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ],
          if (fileName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              fileName,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: 12),
            _GradeBox(grade: data, noteMax: noteMax),
          ],
        ],
      ),
    );
  }
}

class _GradeBox extends StatelessWidget {
  final Map<String, dynamic> grade;
  final dynamic noteMax;

  const _GradeBox({
    required this.grade,
    this.noteMax,
  });

  @override
  Widget build(BuildContext context) {
    final value = grade['score'] ?? grade['note'];
    final numeric = double.tryParse(value.toString()) ?? 0;

    Color color;
    if (numeric >= 14) {
      color = _green;
    } else if (numeric >= 10) {
      color = _amber;
    } else {
      color = _red;
    }

    final comment = _str(grade['commentaire'] ?? grade['feedback']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Grade: $value/${noteMax ?? ''}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              comment,
              style: TextStyle(
                color: color.withOpacity(0.85),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _EmptyCard({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(icon, color: _muted, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _red, size: 56),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
            const SizedBox(height: 22),
            _FullButton(
              text: buttonText,
              icon: Icons.refresh_rounded,
              color: _primary,
              onTap: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data helpers
// ─────────────────────────────────────────────────────────────────────────────

String _str(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final s = value.toString();
  return s.isEmpty ? fallback : s;
}

num _num(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value.toString()) ?? 0;
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return [];
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;

  try {
    return DateTime.parse(value.toString()).toLocal();
  } catch (_) {
    return null;
  }
}

String _formatDate(String value) {
  final date = _parseDate(value);
  if (date == null) return '';
  return _formatDateObj(date);
}

String _formatDateObj(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _formatTimeObj(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

String _instructorName(Map<String, dynamic> course) {
  final e = course['enseignant'];

  if (e is Map<String, dynamic>) {
    final prenom = _str(e['prenom']);
    final nom = _str(e['nom']);

    if (prenom.isNotEmpty || nom.isNotEmpty) {
      return '$prenom $nom'.trim();
    }

    return _str(e['name'], fallback: 'TBA');
  }

  return _str(course['enseignantNom'], fallback: 'TBA');
}

String _className(Map<String, dynamic> course) {
  final c = course['classe'];

  if (c is Map<String, dynamic>) {
    return _str(c['nom'], fallback: 'General');
  }

  return _str(course['classeNom'], fallback: 'General');
}