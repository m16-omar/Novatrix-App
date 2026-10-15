import 'json.dart';

/// The website's services, programs, solutions, industries, and insights articles, bundled in
/// assets/content/site.json (refresh it with `node tool/sync_site_content.js`). The home page's
/// hand-copied text is in SiteContent (data/site_content.dart).
class SiteCatalog {
  const SiteCatalog({
    required this.offerings,
    required this.programs,
    required this.solutions,
    required this.industries,
    required this.insights,
  });

  /// The four core services: software, implementation, integration, and support.
  final List<Offering> offerings;

  /// Training for organizations: corporate training and youth and workforce programs.
  final List<Offering> programs;

  /// Typical solutions: platforms, automation, data, learning platforms, portals.
  final List<Offering> solutions;
  final List<Industry> industries;
  final List<Insight> insights;

  factory SiteCatalog.fromJson(Json j) => SiteCatalog(
        offerings: jsonList(j['offerings']).map(Offering.fromJson).toList(),
        programs: jsonList(j['programs']).map(Offering.fromJson).toList(),
        solutions: jsonList(j['solutions']).map(Offering.fromJson).toList(),
        industries: jsonList(j['industries']).map(Industry.fromJson).toList(),
        insights: jsonList(j['insights']).map(Insight.fromJson).toList(),
      );

  List<Offering> get allOfferings => [...offerings, ...programs, ...solutions];

  Offering? offering(String slug) => allOfferings.where((o) => o.slug == slug).firstOrNull;
  Industry? industry(String slug) => industries.where((i) => i.slug == slug).firstOrNull;
  Insight? insight(String slug) => insights.where((i) => i.slug == slug).firstOrNull;

  /// The offering a website path points to ("/system-implementation", "/solutions/data-and-ai").
  Offering? offeringForPath(String path) => allOfferings.where((o) => o.path == path).firstOrNull;
}

/// A titled item with a short description ("Needs assessment", "Current-state review, ...").
class Item {
  const Item(this.title, this.description);
  final String title;
  final String description;

  factory Item.fromJson(Json j) => Item(str(j['title']), str(j['desc']));
}

class Faq {
  const Faq(this.question, this.answer);
  final String question;
  final String answer;

  factory Faq.fromJson(Json j) => Faq(str(j['q']), str(j['a']));
}

/// What a call to action leads to: a project inquiry, a support request, or a training inquiry.
enum CtaForm { project, support, training }

/// A service, training program, or solution page.
class Offering {
  const Offering({
    required this.slug,
    required this.path,
    required this.name,
    required this.eyebrow,
    required this.title,
    required this.summary,
    required this.intro,
    required this.audience,
    required this.problemHeading,
    required this.problemBody,
    required this.problemPoints,
    required this.capabilities,
    required this.boundaries,
    required this.engagementTypes,
    required this.process,
    required this.industries,
    required this.faqs,
    required this.ctaLabel,
    required this.ctaForm,
    required this.ctaService,
    required this.ctaHeading,
    required this.ctaBody,
  });

  final String slug;

  /// Its page on the website, e.g. "/software-development".
  final String path;
  final String name;
  final String eyebrow;
  final String title;
  final String summary;
  final String intro;
  final String audience;
  final String problemHeading;
  final String problemBody;
  final List<String> problemPoints;
  final List<Item> capabilities;
  final String boundaries;
  final List<Item> engagementTypes;
  final List<Item> process;

  /// Industry slugs this applies to.
  final List<String> industries;
  final List<Faq> faqs;
  final String ctaLabel;
  final CtaForm ctaForm;

  /// The consultation form's service value, for project inquiries.
  final String? ctaService;
  final String ctaHeading;
  final String ctaBody;

  factory Offering.fromJson(Json j) {
    final problem = jsonOf(j['problem']);
    final cta = jsonOf(j['cta']);
    return Offering(
      slug: str(j['slug']),
      path: str(j['path']),
      name: str(j['name']),
      eyebrow: str(j['eyebrow']),
      title: str(j['title']),
      summary: str(j['summary']),
      intro: str(j['intro']),
      audience: str(j['audience']),
      problemHeading: str(problem['heading']),
      problemBody: str(problem['body']),
      problemPoints: strings(problem['points']),
      capabilities: jsonList(j['capabilities']).map(Item.fromJson).toList(),
      boundaries: str(j['boundaries']),
      engagementTypes: jsonList(j['engagementTypes']).map(Item.fromJson).toList(),
      process: jsonList(j['process']).map(Item.fromJson).toList(),
      industries: strings(j['industries']),
      faqs: jsonList(j['faqs']).map(Faq.fromJson).toList(),
      ctaLabel: str(cta['label']),
      ctaForm: CtaForm.values.where((f) => f.name == cta['form']).firstOrNull ?? CtaForm.project,
      ctaService: strOrNull(cta['service']),
      ctaHeading: str(cta['heading']),
      ctaBody: str(cta['body']),
    );
  }
}

class Industry {
  const Industry({
    required this.slug,
    required this.name,
    required this.title,
    required this.summary,
    required this.intro,
    required this.problems,
    required this.servicePaths,
    required this.sampleSolutions,
    required this.training,
  });

  final String slug;
  final String name;
  final String title;
  final String summary;
  final String intro;
  final List<String> problems;

  /// Website paths of the services and solutions that fit this sector.
  final List<String> servicePaths;
  final List<Item> sampleSolutions;
  final String training;

  factory Industry.fromJson(Json j) => Industry(
        slug: str(j['slug']),
        name: str(j['name']),
        title: str(j['title']),
        summary: str(j['summary']),
        intro: str(j['intro']),
        problems: strings(j['problems']),
        servicePaths: strings(j['services']),
        sampleSolutions: jsonList(j['sampleSolutions']).map(Item.fromJson).toList(),
        training: str(j['training']),
      );
}

enum BlockType { heading, paragraph, bullets }

/// A piece of an article: a heading, a paragraph, or a bulleted list.
class Block {
  const Block(this.type, this.text, this.items);
  final BlockType type;
  final String text;
  final List<String> items;

  factory Block.fromJson(Json j) => Block(
        switch (j['type']) {
          'h2' => BlockType.heading,
          'ul' => BlockType.bullets,
          _ => BlockType.paragraph,
        },
        str(j['text']),
        strings(j['items']),
      );
}

class Insight {
  const Insight({
    required this.slug,
    required this.title,
    required this.summary,
    required this.category,
    required this.author,
    required this.date,
    required this.readMinutes,
    required this.body,
    required this.ctaLabel,
    required this.ctaPath,
    required this.related,
  });

  final String slug;
  final String title;
  final String summary;
  final String category;
  final String author;
  final DateTime? date;
  final int readMinutes;
  final List<Block> body;
  final String ctaLabel;

  /// The website path the call to action points to, e.g. "/system-implementation".
  final String ctaPath;
  final List<String> related;

  factory Insight.fromJson(Json j) {
    final cta = jsonOf(j['cta']);
    return Insight(
      slug: str(j['slug']),
      title: str(j['title']),
      summary: str(j['summary']),
      category: str(j['category']),
      author: str(j['author']),
      date: DateTime.tryParse(str(j['date'])),
      readMinutes: intOf(j['readMinutes']),
      body: jsonList(j['body']).map(Block.fromJson).toList(),
      ctaLabel: str(cta['label']),
      ctaPath: str(cta['to']),
      related: strings(j['related']),
    );
  }
}
