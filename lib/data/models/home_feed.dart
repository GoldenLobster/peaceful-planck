import 'search_result.dart';

class HomeSection {
  final String title;
  final SearchResults contents;

  const HomeSection({
    required this.title,
    required this.contents,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    final titleObj = json['header']?['title'];
    final title = titleObj is Map ? titleObj['text'] : (titleObj ?? 'Recommendations');
    
    final contentsList = json['contents'] as List<dynamic>? ?? [];
    
    return HomeSection(
      title: title as String,
      contents: SearchResults.fromJson(contentsList),
    );
  }
}

class HomeFeed {
  final List<HomeSection> sections;

  const HomeFeed({this.sections = const []});

  factory HomeFeed.fromJson(List<dynamic> jsonList) {
    final sections = <HomeSection>[];
    for (var item in jsonList) {
      if (item is Map<String, dynamic>) {
         // Some sections might not have contents
         if (item['contents'] != null) {
            sections.add(HomeSection.fromJson(item));
         }
      }
    }
    return HomeFeed(sections: sections);
  }
}
