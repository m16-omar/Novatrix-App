import 'json.dart';

class Profile {
  const Profile({
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.bio = '',
    this.country = '',
    this.stateOrCity = '',
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String bio;
  final String country;
  final String stateOrCity;

  factory Profile.fromJson(Json j) => Profile(
        firstName: str(j['first_name']),
        lastName: str(j['last_name']),
        phone: str(j['phone']),
        bio: str(j['bio']),
        country: str(j['country']),
        stateOrCity: str(j['state_or_city']),
      );

  Json toJson() => {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'phone': phone.trim(),
        'bio': bio.trim(),
        'country': country.trim(),
        'state_or_city': stateOrCity.trim(),
      };

  String get location => [stateOrCity, country].where((s) => s.isNotEmpty).join(', ');
}

class User {
  const User({
    required this.id,
    required this.email,
    this.dateJoined,
    this.profile = const Profile(),
    this.emailVerified = true,
    this.isStaff = false,
  });

  final int id;
  final String email;
  final DateTime? dateJoined;
  final Profile profile;

  /// False until the address is confirmed with the code emailed at sign-up.
  final bool emailVerified;
  final bool isStaff;

  /// Learners and clients confirm their email before using their areas. Staff accounts are created
  /// internally and skip it, as on the backend.
  bool get needsEmailVerification => !emailVerified && !isStaff;

  factory User.fromJson(Json j) => User(
        id: intOf(j['id']),
        email: str(j['email']),
        dateJoined: dateOf(j['date_joined']),
        profile: j['profile'] is Map ? Profile.fromJson(jsonOf(j['profile'])) : const Profile(),
        // Older backends don't send the flag: treat their accounts as confirmed.
        emailVerified: j['is_email_verified'] == null || boolOf(j['is_email_verified']),
        isStaff: boolOf(j['is_staff']),
      );

  /// The same shape as the API's user, so a saved copy reads back through [User.fromJson].
  Json toJson() => {
        'id': id,
        'email': email,
        'date_joined': dateJoined?.toUtc().toIso8601String(),
        'profile': profile.toJson(),
        'is_email_verified': emailVerified,
        'is_staff': isStaff,
      };

  User copyWith({Profile? profile, bool? emailVerified}) => User(
        id: id,
        email: email,
        dateJoined: dateJoined,
        profile: profile ?? this.profile,
        emailVerified: emailVerified ?? this.emailVerified,
        isStaff: isStaff,
      );

  String get firstName => profile.firstName.isNotEmpty ? profile.firstName : email.split('@').first;

  String get fullName {
    final name = '${profile.firstName} ${profile.lastName}'.trim();
    return name.isNotEmpty ? name : firstName;
  }

  String get initials {
    final f = profile.firstName.trim();
    final l = profile.lastName.trim();
    if (f.isNotEmpty && l.isNotEmpty) return (f[0] + l[0]).toUpperCase();
    return (f.isNotEmpty ? f[0] : (email.isNotEmpty ? email[0] : '?')).toUpperCase();
  }
}

/// Which areas of the app someone can use, from `GET /services/me/roles/`.
class Roles {
  const Roles({
    this.isFacilitator = false,
    this.facilitatedCourses = 0,
    this.enrolledCourses = 0,
    this.hasClientProjects = false,
    this.pendingReviews = 0,
    this.clientProjects = 0,
    this.openTickets = 0,
  });

  final bool isFacilitator;
  final int facilitatedCourses;
  final int enrolledCourses;
  final bool hasClientProjects;
  final int pendingReviews;
  final int clientProjects;
  final int openTickets;

  static const none = Roles();

  Json toJson() => {
        'is_facilitator': isFacilitator,
        'facilitated_courses': facilitatedCourses,
        'enrolled_courses': enrolledCourses,
        'has_client_projects': hasClientProjects,
        'pending_reviews': pendingReviews,
        'client_projects': clientProjects,
        'open_tickets': openTickets,
      };

  factory Roles.fromJson(Json j) => Roles(
        isFacilitator: boolOf(j['is_facilitator']),
        facilitatedCourses: intOf(j['facilitated_courses']),
        enrolledCourses: intOf(j['enrolled_courses']),
        hasClientProjects: boolOf(j['has_client_projects']),
        pendingReviews: intOf(j['pending_reviews']),
        clientProjects: intOf(j['client_projects']),
        openTickets: intOf(j['open_tickets']),
      );
}
