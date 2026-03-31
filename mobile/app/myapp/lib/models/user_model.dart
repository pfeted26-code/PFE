// ─── User Model ───────────────────────────────────────────────────────────────
// Represents the user object returned by the API after login.
// Mirrors the backend User schema fields.

class UserModel {
  final String id;
  final String email;
  final String role;      // 'admin' | 'enseignant' | 'etudiant'
  final String? nom;
  final String? prenom;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.nom,
    this.prenom,
  });

  // ── Deserialization ─────────────────────────────────────────────────────────

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:     (json['_id'] ?? json['id'] ?? '') as String,
      email:  (json['email']  ?? '')             as String,
      role:   (json['role']   ?? '')             as String,
      nom:    json['nom']    as String?,
      prenom: json['prenom'] as String?,
    );
  }

  // ── Serialization ───────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id':     id,
    'email':  email,
    'role':   role,
    if (nom    != null) 'nom':    nom,
    if (prenom != null) 'prenom': prenom,
  };

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String get fullName {
    if (prenom != null && nom != null) return '$prenom $nom';
    if (prenom != null) return prenom!;
    if (nom    != null) return nom!;
    return email;
  }

  bool get isAdmin      => role == 'admin';
  bool get isTeacher    => role == 'enseignant';
  bool get isStudent    => role == 'etudiant';

  @override
  String toString() => 'UserModel(id: $id, email: $email, role: $role)';
}