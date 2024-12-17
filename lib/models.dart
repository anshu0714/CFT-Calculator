class Party {
  final String name;
  final String number;
  final String email;
  final List<TableSheet> tableSheets;

  Party({
    required this.name,
    required this.number,
    required this.email,
    required this.tableSheets,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'number': number,
      'email': email,
      'tableSheets': tableSheets.map((sheet) => sheet.toJson()).toList(),
    };
  }

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      name: json['name'],
      number: json['number'],
      email: json['email'],
      tableSheets: (json['tableSheets'] as List<dynamic>)
          .map((item) => TableSheet.fromJson(item))
          .toList(),
    );
  }
}

class TableSheet {
  final String title;
  final List<String> data;

  TableSheet({required this.title, required this.data});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'data': data,
    };
  }

  factory TableSheet.fromJson(Map<String, dynamic> json) {
    return TableSheet(
      title: json['title'],
      data: List<String>.from(json['data']),
    );
  }
}
