import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Marketing content from thenovatrix.com (home and About pages, October 2026), so the app tells the
/// same story as the website. The backend has no API for it, and this copy is written into the website's
/// page layouts rather than its data: update this file when the website copy changes. The services,
/// industries, and insights articles are synced separately (SiteCatalog, tool/sync_site_content.js).
/// Paths are relative to AppConfig.siteUrl.
class SiteContent {
  SiteContent._();

  static const announcement = 'New cohort starts soon — secure your seat at The Novatrix.';

  static const heroEyebrow = 'Software · Implementation · Training';
  static const heroTitle = 'Build better systems.';
  static const heroTitleAccent = 'Equip better teams.';
  static const heroIntro =
      'Novatrix develops custom software, implements reliable digital systems, and provides practical '
      'technology training for businesses, institutions, nonprofits, and emerging professionals across '
      'Africa and beyond.';

  // About page
  static const aboutTitle = 'We build software, implement systems, and train the people who use them.';
  static const aboutIntro =
      'Novatrix is a technology development, system implementation, and workforce training company. We '
      'connect technology build, operational adoption, workforce capability, and continuous improvement in '
      'one delivery model.';
  static const mission =
      'To design practical digital solutions, successfully implement technology systems, and equip '
      'individuals and organizations with the skills needed to thrive in a technology-driven world.';
  static const vision =
      'To become a trusted African technology and workforce development company delivering locally '
      'relevant solutions with global standards.';
  static const existTitle = 'Technology creates value only when people use it well.';
  static const existText =
      'Software must be correctly designed, successfully implemented, adopted by its users, and continuously '
      'supported. Most providers cover one of those steps. We connect all of them.';
  static const values = [
    ('Practical innovation', 'Innovation grounded in practical use.'),
    ('Reliability', 'Delivery discipline and dependable systems.'),
    ('Accessibility', 'Inclusive participation for every user and learner.'),
    ('Integrity', 'Transparency and responsible technology.'),
    ('Workforce readiness', 'Practical learning that prepares people for real work.'),
    ('Partnership', 'Client partnership and continuous improvement.'),
  ];
  static const commitments =
      "We design for accessibility, collect only the data we need, treat security as a requirement from the "
      "start, and never claim accreditation, compliance, partnerships, or outcomes we can't evidence.";
  static const location = 'Remote · Worldwide';

  static const whyTitle = "Technology shouldn't stop at deployment.";
  static const whyIntro =
      'A system delivers value only when it is properly designed, successfully implemented, and confidently '
      'used. Novatrix supports clients throughout the complete digital transformation journey — from '
      'requirements gathering and product design to development, implementation, training, maintenance, '
      'and optimization.';
  static const pillars = [
    ('Software that works.', 'Designed around real users and real workflows, and tested before launch.'),
    ('Systems that scale.', 'Implemented, integrated, and supported so they keep delivering value.'),
    ('Training that lasts.', 'Practical skills that help people adopt technology with confidence.'),
  ];

  static const servicesTitle = 'Four connected services. One delivery partner.';
  static const servicesIntro =
      'Novatrix develops the solution, implements the system, trains the users, and supports long-term success.';
  static const services = [
    Service(
      icon: LucideIcons.code,
      title: 'Custom Software Development',
      description: 'Secure, scalable, and user-friendly web, mobile, portal, dashboard, automation, data, and '
          'integration solutions tailored to operational needs.',
      action: 'Explore Software Development',
      path: '/software-development',
    ),
    Service(
      icon: LucideIcons.settings,
      title: 'System Implementation',
      description: 'Assessment, selection, configuration, migration, workflow redesign, integration, testing, '
          'go-live, and optimization.',
      action: 'Schedule a System Assessment',
      path: '/system-implementation',
    ),
    Service(
      icon: LucideIcons.graduationCap,
      title: 'Technology Training and Workforce Development',
      description: 'Hands-on training from digital foundations to software, data, AI, cloud, cybersecurity '
          'awareness, and project delivery.',
      action: 'Explore Training Programs',
      path: '/technology-training',
    ),
    Service(
      icon: LucideIcons.headphones,
      title: 'Support and System Optimization',
      description: 'Maintenance, monitoring, updates, issue resolution, enhancements, user assistance, backup, '
          'recovery, and refresher training.',
      action: 'Get Technical Support',
      path: '/support-and-maintenance',
    ),
  ];

  static const industriesTitle = 'Solutions shaped by your sector.';
  static const industriesIntro =
      'We work with organizations whose needs we understand, and confirm sector requirements during discovery.';
  static const deliveryTitle = 'A clear path from discovery to lasting results.';
  static const deliveryIntro = 'Every engagement follows the same disciplined process, adapted to its scope.';
  static const delivery = [
    ('Discover', 'Understand goals, users, workflows, systems, constraints, and success measures.'),
    ('Define', 'Document requirements, scope, deliverables, timeline, responsibilities, risks, and acceptance criteria.'),
    ('Design', 'Create architecture, user journeys, prototypes, data structures, and the implementation plan.'),
    ('Develop or Configure', 'Build the custom solution, or configure and integrate the selected platform.'),
    ('Test', 'Functional, security, usability, accessibility, performance, and user acceptance testing.'),
    ('Train', 'Prepare administrators and users through practical training, documentation, and guided exercises.'),
    ('Launch', 'Deploy, migrate approved data, support go-live, and resolve initial issues.'),
    ('Support and Optimize', 'Monitor, maintain, collect feedback, and introduce improvements.'),
  ];

  static const trainingTitle = 'Learning designed for real work.';
  static const trainingReasons = [
    (LucideIcons.award, 'Certificates of completion.',
        'Complete the projects and assessments to earn a Novatrix certificate of completion.'),
    (LucideIcons.wrench, 'Hands-on with the tools used in industry.',
        'Build with the same stack professionals ship with every day.'),
    (LucideIcons.idCard, 'A professional profile that shows your skills.',
        'We help you present your projects and skills clearly on LinkedIn and in your portfolio.'),
    (LucideIcons.folderGit2, 'Portfolio-ready projects.', 'Apply your skills to practical projects that mirror real work.'),
    (LucideIcons.messagesSquare, 'Guidance when you need it.',
        'Personalized feedback that helps you navigate your learning and career with clarity.'),
  ];
  static const tools = ['Python', 'SQL', 'PowerBI', 'Tableau', 'Excel', 'Git', 'AWS', 'Figma'];

  static const impactTitle = 'Our achievements at The Novatrix.';
  static const impactIntro = 'A snapshot of what our community accomplished in the past year.';
  static const impact = [
    ('450+', 'Learners trained across our programs'),
    ('72%', 'Connected to local & global opportunities'),
    ('18', 'Countries represented in our community'),
  ];

  static const testimonialsTitle = 'See what our learners are achieving.';
  static const testimonials = [
    ('The Novatrix made my switch into data analytics feel inevitable. The mentorship was unreal.', 'Amara Okafor', 'Data Analyst'),
    ('I shipped my first ML project in week six. The cohort kept me accountable the whole way.', 'Daniel Park', 'ML Engineer'),
    ('From zero to AWS-confident in a few months. Hands-on labs are the secret.', 'Lerato Mokoena', 'Cloud Engineer'),
    ("Mentors actually reviewed my code line by line. That's where the real growth happened.", 'Priya Nair', 'Frontend Dev'),
    ('The portfolio I built here got me into final interviews at three companies.', 'Marcus Lin', 'Data Scientist'),
    ('Loved how feedback flowed both ways — they actually listened to learners.', 'Zainab Yusuf', 'Product Analyst'),
  ];

  static const insightsTitle = 'Practical guidance from our team.';
  static const ctaTitle = "Let's talk about your next step.";
  static const ctaText = 'Need a digital solution, a stronger implementation plan, or practical technology training? '
      'Talk with Novatrix about the next step.';

  static const policies = [
    ('Privacy Policy', '/legal/privacy-policy'),
    ('Terms of Use', '/legal/terms-of-use'),
    ('Cookie Notice', '/legal/cookie-notice'),
    ('Accessibility Statement', '/legal/accessibility-statement'),
    ('Data Protection Statement', '/legal/data-protection'),
    ('Training Cancellation and Refund Policy', '/legal/training-refund-policy'),
  ];
}

class Service {
  const Service({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    required this.path,
  });

  final IconData icon;
  final String title;
  final String description;
  final String action;
  final String path;
}
