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
  const User({required this.id, required this.email, this.dateJoined, this.profile = const Profile()});

  final int id;
  final String email;
  final DateTime? dateJoined;
  final Profile profile;

  factory User.fromJson(Json j) => User(
        id: intOf(j['id']),
        email: str(j['email']),
        dateJoined: dateOf(j['date_joined']),
        profile: j['profile'] is Map ? Profile.fromJson(jsonOf(j['profile'])) : const Profile(),
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
