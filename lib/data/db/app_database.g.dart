// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ScenariosTable extends Scenarios
    with TableInfo<$ScenariosTable, Scenario> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScenariosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleZhMeta = const VerificationMeta(
    'titleZh',
  );
  @override
  late final GeneratedColumn<String> titleZh = GeneratedColumn<String>(
    'title_zh',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleEnMeta = const VerificationMeta(
    'titleEn',
  );
  @override
  late final GeneratedColumn<String> titleEn = GeneratedColumn<String>(
    'title_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aiRoleMeta = const VerificationMeta('aiRole');
  @override
  late final GeneratedColumn<String> aiRole = GeneratedColumn<String>(
    'ai_role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userGoalMeta = const VerificationMeta(
    'userGoal',
  );
  @override
  late final GeneratedColumn<String> userGoal = GeneratedColumn<String>(
    'user_goal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingLineMeta = const VerificationMeta(
    'openingLine',
  );
  @override
  late final GeneratedColumn<String> openingLine = GeneratedColumn<String>(
    'opening_line',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetPhrasesMeta = const VerificationMeta(
    'targetPhrases',
  );
  @override
  late final GeneratedColumn<String> targetPhrases = GeneratedColumn<String>(
    'target_phrases',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedTurnsMeta = const VerificationMeta(
    'expectedTurns',
  );
  @override
  late final GeneratedColumn<int> expectedTurns = GeneratedColumn<int>(
    'expected_turns',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _successCriteriaMeta = const VerificationMeta(
    'successCriteria',
  );
  @override
  late final GeneratedColumn<String> successCriteria = GeneratedColumn<String>(
    'success_criteria',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchHintMeta = const VerificationMeta(
    'branchHint',
  );
  @override
  late final GeneratedColumn<String> branchHint = GeneratedColumn<String>(
    'branch_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isBuiltinMeta = const VerificationMeta(
    'isBuiltin',
  );
  @override
  late final GeneratedColumn<int> isBuiltin = GeneratedColumn<int>(
    'is_builtin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    titleZh,
    titleEn,
    category,
    level,
    aiRole,
    userGoal,
    openingLine,
    targetPhrases,
    expectedTurns,
    successCriteria,
    branchHint,
    isBuiltin,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scenario';
  @override
  VerificationContext validateIntegrity(
    Insertable<Scenario> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title_zh')) {
      context.handle(
        _titleZhMeta,
        titleZh.isAcceptableOrUnknown(data['title_zh']!, _titleZhMeta),
      );
    } else if (isInserting) {
      context.missing(_titleZhMeta);
    }
    if (data.containsKey('title_en')) {
      context.handle(
        _titleEnMeta,
        titleEn.isAcceptableOrUnknown(data['title_en']!, _titleEnMeta),
      );
    } else if (isInserting) {
      context.missing(_titleEnMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('ai_role')) {
      context.handle(
        _aiRoleMeta,
        aiRole.isAcceptableOrUnknown(data['ai_role']!, _aiRoleMeta),
      );
    } else if (isInserting) {
      context.missing(_aiRoleMeta);
    }
    if (data.containsKey('user_goal')) {
      context.handle(
        _userGoalMeta,
        userGoal.isAcceptableOrUnknown(data['user_goal']!, _userGoalMeta),
      );
    } else if (isInserting) {
      context.missing(_userGoalMeta);
    }
    if (data.containsKey('opening_line')) {
      context.handle(
        _openingLineMeta,
        openingLine.isAcceptableOrUnknown(
          data['opening_line']!,
          _openingLineMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingLineMeta);
    }
    if (data.containsKey('target_phrases')) {
      context.handle(
        _targetPhrasesMeta,
        targetPhrases.isAcceptableOrUnknown(
          data['target_phrases']!,
          _targetPhrasesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetPhrasesMeta);
    }
    if (data.containsKey('expected_turns')) {
      context.handle(
        _expectedTurnsMeta,
        expectedTurns.isAcceptableOrUnknown(
          data['expected_turns']!,
          _expectedTurnsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedTurnsMeta);
    }
    if (data.containsKey('success_criteria')) {
      context.handle(
        _successCriteriaMeta,
        successCriteria.isAcceptableOrUnknown(
          data['success_criteria']!,
          _successCriteriaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_successCriteriaMeta);
    }
    if (data.containsKey('branch_hint')) {
      context.handle(
        _branchHintMeta,
        branchHint.isAcceptableOrUnknown(data['branch_hint']!, _branchHintMeta),
      );
    }
    if (data.containsKey('is_builtin')) {
      context.handle(
        _isBuiltinMeta,
        isBuiltin.isAcceptableOrUnknown(data['is_builtin']!, _isBuiltinMeta),
      );
    } else if (isInserting) {
      context.missing(_isBuiltinMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Scenario map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Scenario(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      titleZh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_zh'],
      )!,
      titleEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_en'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      aiRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_role'],
      )!,
      userGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_goal'],
      )!,
      openingLine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opening_line'],
      )!,
      targetPhrases: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_phrases'],
      )!,
      expectedTurns: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_turns'],
      )!,
      successCriteria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}success_criteria'],
      )!,
      branchHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_hint'],
      ),
      isBuiltin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_builtin'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ScenariosTable createAlias(String alias) {
    return $ScenariosTable(attachedDatabase, alias);
  }
}

class Scenario extends DataClass implements Insertable<Scenario> {
  final String id;
  final String titleZh;
  final String titleEn;
  final String category;
  final String level;
  final String aiRole;
  final String userGoal;
  final String openingLine;
  final String targetPhrases;
  final int expectedTurns;
  final String successCriteria;
  final String? branchHint;
  final int isBuiltin;
  final int sortOrder;
  const Scenario({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    required this.category,
    required this.level,
    required this.aiRole,
    required this.userGoal,
    required this.openingLine,
    required this.targetPhrases,
    required this.expectedTurns,
    required this.successCriteria,
    this.branchHint,
    required this.isBuiltin,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title_zh'] = Variable<String>(titleZh);
    map['title_en'] = Variable<String>(titleEn);
    map['category'] = Variable<String>(category);
    map['level'] = Variable<String>(level);
    map['ai_role'] = Variable<String>(aiRole);
    map['user_goal'] = Variable<String>(userGoal);
    map['opening_line'] = Variable<String>(openingLine);
    map['target_phrases'] = Variable<String>(targetPhrases);
    map['expected_turns'] = Variable<int>(expectedTurns);
    map['success_criteria'] = Variable<String>(successCriteria);
    if (!nullToAbsent || branchHint != null) {
      map['branch_hint'] = Variable<String>(branchHint);
    }
    map['is_builtin'] = Variable<int>(isBuiltin);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ScenariosCompanion toCompanion(bool nullToAbsent) {
    return ScenariosCompanion(
      id: Value(id),
      titleZh: Value(titleZh),
      titleEn: Value(titleEn),
      category: Value(category),
      level: Value(level),
      aiRole: Value(aiRole),
      userGoal: Value(userGoal),
      openingLine: Value(openingLine),
      targetPhrases: Value(targetPhrases),
      expectedTurns: Value(expectedTurns),
      successCriteria: Value(successCriteria),
      branchHint: branchHint == null && nullToAbsent
          ? const Value.absent()
          : Value(branchHint),
      isBuiltin: Value(isBuiltin),
      sortOrder: Value(sortOrder),
    );
  }

  factory Scenario.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Scenario(
      id: serializer.fromJson<String>(json['id']),
      titleZh: serializer.fromJson<String>(json['titleZh']),
      titleEn: serializer.fromJson<String>(json['titleEn']),
      category: serializer.fromJson<String>(json['category']),
      level: serializer.fromJson<String>(json['level']),
      aiRole: serializer.fromJson<String>(json['aiRole']),
      userGoal: serializer.fromJson<String>(json['userGoal']),
      openingLine: serializer.fromJson<String>(json['openingLine']),
      targetPhrases: serializer.fromJson<String>(json['targetPhrases']),
      expectedTurns: serializer.fromJson<int>(json['expectedTurns']),
      successCriteria: serializer.fromJson<String>(json['successCriteria']),
      branchHint: serializer.fromJson<String?>(json['branchHint']),
      isBuiltin: serializer.fromJson<int>(json['isBuiltin']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'titleZh': serializer.toJson<String>(titleZh),
      'titleEn': serializer.toJson<String>(titleEn),
      'category': serializer.toJson<String>(category),
      'level': serializer.toJson<String>(level),
      'aiRole': serializer.toJson<String>(aiRole),
      'userGoal': serializer.toJson<String>(userGoal),
      'openingLine': serializer.toJson<String>(openingLine),
      'targetPhrases': serializer.toJson<String>(targetPhrases),
      'expectedTurns': serializer.toJson<int>(expectedTurns),
      'successCriteria': serializer.toJson<String>(successCriteria),
      'branchHint': serializer.toJson<String?>(branchHint),
      'isBuiltin': serializer.toJson<int>(isBuiltin),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Scenario copyWith({
    String? id,
    String? titleZh,
    String? titleEn,
    String? category,
    String? level,
    String? aiRole,
    String? userGoal,
    String? openingLine,
    String? targetPhrases,
    int? expectedTurns,
    String? successCriteria,
    Value<String?> branchHint = const Value.absent(),
    int? isBuiltin,
    int? sortOrder,
  }) => Scenario(
    id: id ?? this.id,
    titleZh: titleZh ?? this.titleZh,
    titleEn: titleEn ?? this.titleEn,
    category: category ?? this.category,
    level: level ?? this.level,
    aiRole: aiRole ?? this.aiRole,
    userGoal: userGoal ?? this.userGoal,
    openingLine: openingLine ?? this.openingLine,
    targetPhrases: targetPhrases ?? this.targetPhrases,
    expectedTurns: expectedTurns ?? this.expectedTurns,
    successCriteria: successCriteria ?? this.successCriteria,
    branchHint: branchHint.present ? branchHint.value : this.branchHint,
    isBuiltin: isBuiltin ?? this.isBuiltin,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Scenario copyWithCompanion(ScenariosCompanion data) {
    return Scenario(
      id: data.id.present ? data.id.value : this.id,
      titleZh: data.titleZh.present ? data.titleZh.value : this.titleZh,
      titleEn: data.titleEn.present ? data.titleEn.value : this.titleEn,
      category: data.category.present ? data.category.value : this.category,
      level: data.level.present ? data.level.value : this.level,
      aiRole: data.aiRole.present ? data.aiRole.value : this.aiRole,
      userGoal: data.userGoal.present ? data.userGoal.value : this.userGoal,
      openingLine: data.openingLine.present
          ? data.openingLine.value
          : this.openingLine,
      targetPhrases: data.targetPhrases.present
          ? data.targetPhrases.value
          : this.targetPhrases,
      expectedTurns: data.expectedTurns.present
          ? data.expectedTurns.value
          : this.expectedTurns,
      successCriteria: data.successCriteria.present
          ? data.successCriteria.value
          : this.successCriteria,
      branchHint: data.branchHint.present
          ? data.branchHint.value
          : this.branchHint,
      isBuiltin: data.isBuiltin.present ? data.isBuiltin.value : this.isBuiltin,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Scenario(')
          ..write('id: $id, ')
          ..write('titleZh: $titleZh, ')
          ..write('titleEn: $titleEn, ')
          ..write('category: $category, ')
          ..write('level: $level, ')
          ..write('aiRole: $aiRole, ')
          ..write('userGoal: $userGoal, ')
          ..write('openingLine: $openingLine, ')
          ..write('targetPhrases: $targetPhrases, ')
          ..write('expectedTurns: $expectedTurns, ')
          ..write('successCriteria: $successCriteria, ')
          ..write('branchHint: $branchHint, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    titleZh,
    titleEn,
    category,
    level,
    aiRole,
    userGoal,
    openingLine,
    targetPhrases,
    expectedTurns,
    successCriteria,
    branchHint,
    isBuiltin,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Scenario &&
          other.id == this.id &&
          other.titleZh == this.titleZh &&
          other.titleEn == this.titleEn &&
          other.category == this.category &&
          other.level == this.level &&
          other.aiRole == this.aiRole &&
          other.userGoal == this.userGoal &&
          other.openingLine == this.openingLine &&
          other.targetPhrases == this.targetPhrases &&
          other.expectedTurns == this.expectedTurns &&
          other.successCriteria == this.successCriteria &&
          other.branchHint == this.branchHint &&
          other.isBuiltin == this.isBuiltin &&
          other.sortOrder == this.sortOrder);
}

class ScenariosCompanion extends UpdateCompanion<Scenario> {
  final Value<String> id;
  final Value<String> titleZh;
  final Value<String> titleEn;
  final Value<String> category;
  final Value<String> level;
  final Value<String> aiRole;
  final Value<String> userGoal;
  final Value<String> openingLine;
  final Value<String> targetPhrases;
  final Value<int> expectedTurns;
  final Value<String> successCriteria;
  final Value<String?> branchHint;
  final Value<int> isBuiltin;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ScenariosCompanion({
    this.id = const Value.absent(),
    this.titleZh = const Value.absent(),
    this.titleEn = const Value.absent(),
    this.category = const Value.absent(),
    this.level = const Value.absent(),
    this.aiRole = const Value.absent(),
    this.userGoal = const Value.absent(),
    this.openingLine = const Value.absent(),
    this.targetPhrases = const Value.absent(),
    this.expectedTurns = const Value.absent(),
    this.successCriteria = const Value.absent(),
    this.branchHint = const Value.absent(),
    this.isBuiltin = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScenariosCompanion.insert({
    required String id,
    required String titleZh,
    required String titleEn,
    required String category,
    required String level,
    required String aiRole,
    required String userGoal,
    required String openingLine,
    required String targetPhrases,
    required int expectedTurns,
    required String successCriteria,
    this.branchHint = const Value.absent(),
    required int isBuiltin,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       titleZh = Value(titleZh),
       titleEn = Value(titleEn),
       category = Value(category),
       level = Value(level),
       aiRole = Value(aiRole),
       userGoal = Value(userGoal),
       openingLine = Value(openingLine),
       targetPhrases = Value(targetPhrases),
       expectedTurns = Value(expectedTurns),
       successCriteria = Value(successCriteria),
       isBuiltin = Value(isBuiltin),
       sortOrder = Value(sortOrder);
  static Insertable<Scenario> custom({
    Expression<String>? id,
    Expression<String>? titleZh,
    Expression<String>? titleEn,
    Expression<String>? category,
    Expression<String>? level,
    Expression<String>? aiRole,
    Expression<String>? userGoal,
    Expression<String>? openingLine,
    Expression<String>? targetPhrases,
    Expression<int>? expectedTurns,
    Expression<String>? successCriteria,
    Expression<String>? branchHint,
    Expression<int>? isBuiltin,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (titleZh != null) 'title_zh': titleZh,
      if (titleEn != null) 'title_en': titleEn,
      if (category != null) 'category': category,
      if (level != null) 'level': level,
      if (aiRole != null) 'ai_role': aiRole,
      if (userGoal != null) 'user_goal': userGoal,
      if (openingLine != null) 'opening_line': openingLine,
      if (targetPhrases != null) 'target_phrases': targetPhrases,
      if (expectedTurns != null) 'expected_turns': expectedTurns,
      if (successCriteria != null) 'success_criteria': successCriteria,
      if (branchHint != null) 'branch_hint': branchHint,
      if (isBuiltin != null) 'is_builtin': isBuiltin,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScenariosCompanion copyWith({
    Value<String>? id,
    Value<String>? titleZh,
    Value<String>? titleEn,
    Value<String>? category,
    Value<String>? level,
    Value<String>? aiRole,
    Value<String>? userGoal,
    Value<String>? openingLine,
    Value<String>? targetPhrases,
    Value<int>? expectedTurns,
    Value<String>? successCriteria,
    Value<String?>? branchHint,
    Value<int>? isBuiltin,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ScenariosCompanion(
      id: id ?? this.id,
      titleZh: titleZh ?? this.titleZh,
      titleEn: titleEn ?? this.titleEn,
      category: category ?? this.category,
      level: level ?? this.level,
      aiRole: aiRole ?? this.aiRole,
      userGoal: userGoal ?? this.userGoal,
      openingLine: openingLine ?? this.openingLine,
      targetPhrases: targetPhrases ?? this.targetPhrases,
      expectedTurns: expectedTurns ?? this.expectedTurns,
      successCriteria: successCriteria ?? this.successCriteria,
      branchHint: branchHint ?? this.branchHint,
      isBuiltin: isBuiltin ?? this.isBuiltin,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (titleZh.present) {
      map['title_zh'] = Variable<String>(titleZh.value);
    }
    if (titleEn.present) {
      map['title_en'] = Variable<String>(titleEn.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (aiRole.present) {
      map['ai_role'] = Variable<String>(aiRole.value);
    }
    if (userGoal.present) {
      map['user_goal'] = Variable<String>(userGoal.value);
    }
    if (openingLine.present) {
      map['opening_line'] = Variable<String>(openingLine.value);
    }
    if (targetPhrases.present) {
      map['target_phrases'] = Variable<String>(targetPhrases.value);
    }
    if (expectedTurns.present) {
      map['expected_turns'] = Variable<int>(expectedTurns.value);
    }
    if (successCriteria.present) {
      map['success_criteria'] = Variable<String>(successCriteria.value);
    }
    if (branchHint.present) {
      map['branch_hint'] = Variable<String>(branchHint.value);
    }
    if (isBuiltin.present) {
      map['is_builtin'] = Variable<int>(isBuiltin.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScenariosCompanion(')
          ..write('id: $id, ')
          ..write('titleZh: $titleZh, ')
          ..write('titleEn: $titleEn, ')
          ..write('category: $category, ')
          ..write('level: $level, ')
          ..write('aiRole: $aiRole, ')
          ..write('userGoal: $userGoal, ')
          ..write('openingLine: $openingLine, ')
          ..write('targetPhrases: $targetPhrases, ')
          ..write('expectedTurns: $expectedTurns, ')
          ..write('successCriteria: $successCriteria, ')
          ..write('branchHint: $branchHint, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scenarioIdMeta = const VerificationMeta(
    'scenarioId',
  );
  @override
  late final GeneratedColumn<String> scenarioId = GeneratedColumn<String>(
    'scenario_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _turnCountMeta = const VerificationMeta(
    'turnCount',
  );
  @override
  late final GeneratedColumn<int> turnCount = GeneratedColumn<int>(
    'turn_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintCountMeta = const VerificationMeta(
    'hintCount',
  );
  @override
  late final GeneratedColumn<int> hintCount = GeneratedColumn<int>(
    'hint_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assistTurnsMeta = const VerificationMeta(
    'assistTurns',
  );
  @override
  late final GeneratedColumn<int> assistTurns = GeneratedColumn<int>(
    'assist_turns',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translateCountMeta = const VerificationMeta(
    'translateCount',
  );
  @override
  late final GeneratedColumn<int> translateCount = GeneratedColumn<int>(
    'translate_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ttsEngineMeta = const VerificationMeta(
    'ttsEngine',
  );
  @override
  late final GeneratedColumn<String> ttsEngine = GeneratedColumn<String>(
    'tts_engine',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewJsonMeta = const VerificationMeta(
    'reviewJson',
  );
  @override
  late final GeneratedColumn<String> reviewJson = GeneratedColumn<String>(
    'review_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costEstimateMeta = const VerificationMeta(
    'costEstimate',
  );
  @override
  late final GeneratedColumn<double> costEstimate = GeneratedColumn<double>(
    'cost_estimate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scenarioId,
    startedAt,
    endedAt,
    durationSec,
    turnCount,
    hintCount,
    assistTurns,
    translateCount,
    status,
    modelName,
    ttsEngine,
    reviewJson,
    costEstimate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scenario_id')) {
      context.handle(
        _scenarioIdMeta,
        scenarioId.isAcceptableOrUnknown(data['scenario_id']!, _scenarioIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecMeta);
    }
    if (data.containsKey('turn_count')) {
      context.handle(
        _turnCountMeta,
        turnCount.isAcceptableOrUnknown(data['turn_count']!, _turnCountMeta),
      );
    } else if (isInserting) {
      context.missing(_turnCountMeta);
    }
    if (data.containsKey('hint_count')) {
      context.handle(
        _hintCountMeta,
        hintCount.isAcceptableOrUnknown(data['hint_count']!, _hintCountMeta),
      );
    } else if (isInserting) {
      context.missing(_hintCountMeta);
    }
    if (data.containsKey('assist_turns')) {
      context.handle(
        _assistTurnsMeta,
        assistTurns.isAcceptableOrUnknown(
          data['assist_turns']!,
          _assistTurnsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assistTurnsMeta);
    }
    if (data.containsKey('translate_count')) {
      context.handle(
        _translateCountMeta,
        translateCount.isAcceptableOrUnknown(
          data['translate_count']!,
          _translateCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translateCountMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    }
    if (data.containsKey('tts_engine')) {
      context.handle(
        _ttsEngineMeta,
        ttsEngine.isAcceptableOrUnknown(data['tts_engine']!, _ttsEngineMeta),
      );
    }
    if (data.containsKey('review_json')) {
      context.handle(
        _reviewJsonMeta,
        reviewJson.isAcceptableOrUnknown(data['review_json']!, _reviewJsonMeta),
      );
    }
    if (data.containsKey('cost_estimate')) {
      context.handle(
        _costEstimateMeta,
        costEstimate.isAcceptableOrUnknown(
          data['cost_estimate']!,
          _costEstimateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scenarioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scenario_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      )!,
      turnCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}turn_count'],
      )!,
      hintCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hint_count'],
      )!,
      assistTurns: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}assist_turns'],
      )!,
      translateCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}translate_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      ),
      ttsEngine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tts_engine'],
      ),
      reviewJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_json'],
      ),
      costEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_estimate'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final String? scenarioId;
  final int startedAt;
  final int? endedAt;
  final int durationSec;
  final int turnCount;
  final int hintCount;
  final int assistTurns;
  final int translateCount;
  final String status;
  final String? modelName;
  final String? ttsEngine;
  final String? reviewJson;
  final double? costEstimate;
  const Session({
    required this.id,
    this.scenarioId,
    required this.startedAt,
    this.endedAt,
    required this.durationSec,
    required this.turnCount,
    required this.hintCount,
    required this.assistTurns,
    required this.translateCount,
    required this.status,
    this.modelName,
    this.ttsEngine,
    this.reviewJson,
    this.costEstimate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || scenarioId != null) {
      map['scenario_id'] = Variable<String>(scenarioId);
    }
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<int>(endedAt);
    }
    map['duration_sec'] = Variable<int>(durationSec);
    map['turn_count'] = Variable<int>(turnCount);
    map['hint_count'] = Variable<int>(hintCount);
    map['assist_turns'] = Variable<int>(assistTurns);
    map['translate_count'] = Variable<int>(translateCount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || modelName != null) {
      map['model_name'] = Variable<String>(modelName);
    }
    if (!nullToAbsent || ttsEngine != null) {
      map['tts_engine'] = Variable<String>(ttsEngine);
    }
    if (!nullToAbsent || reviewJson != null) {
      map['review_json'] = Variable<String>(reviewJson);
    }
    if (!nullToAbsent || costEstimate != null) {
      map['cost_estimate'] = Variable<double>(costEstimate);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      scenarioId: scenarioId == null && nullToAbsent
          ? const Value.absent()
          : Value(scenarioId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      durationSec: Value(durationSec),
      turnCount: Value(turnCount),
      hintCount: Value(hintCount),
      assistTurns: Value(assistTurns),
      translateCount: Value(translateCount),
      status: Value(status),
      modelName: modelName == null && nullToAbsent
          ? const Value.absent()
          : Value(modelName),
      ttsEngine: ttsEngine == null && nullToAbsent
          ? const Value.absent()
          : Value(ttsEngine),
      reviewJson: reviewJson == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewJson),
      costEstimate: costEstimate == null && nullToAbsent
          ? const Value.absent()
          : Value(costEstimate),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      scenarioId: serializer.fromJson<String?>(json['scenarioId']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int?>(json['endedAt']),
      durationSec: serializer.fromJson<int>(json['durationSec']),
      turnCount: serializer.fromJson<int>(json['turnCount']),
      hintCount: serializer.fromJson<int>(json['hintCount']),
      assistTurns: serializer.fromJson<int>(json['assistTurns']),
      translateCount: serializer.fromJson<int>(json['translateCount']),
      status: serializer.fromJson<String>(json['status']),
      modelName: serializer.fromJson<String?>(json['modelName']),
      ttsEngine: serializer.fromJson<String?>(json['ttsEngine']),
      reviewJson: serializer.fromJson<String?>(json['reviewJson']),
      costEstimate: serializer.fromJson<double?>(json['costEstimate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scenarioId': serializer.toJson<String?>(scenarioId),
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int?>(endedAt),
      'durationSec': serializer.toJson<int>(durationSec),
      'turnCount': serializer.toJson<int>(turnCount),
      'hintCount': serializer.toJson<int>(hintCount),
      'assistTurns': serializer.toJson<int>(assistTurns),
      'translateCount': serializer.toJson<int>(translateCount),
      'status': serializer.toJson<String>(status),
      'modelName': serializer.toJson<String?>(modelName),
      'ttsEngine': serializer.toJson<String?>(ttsEngine),
      'reviewJson': serializer.toJson<String?>(reviewJson),
      'costEstimate': serializer.toJson<double?>(costEstimate),
    };
  }

  Session copyWith({
    String? id,
    Value<String?> scenarioId = const Value.absent(),
    int? startedAt,
    Value<int?> endedAt = const Value.absent(),
    int? durationSec,
    int? turnCount,
    int? hintCount,
    int? assistTurns,
    int? translateCount,
    String? status,
    Value<String?> modelName = const Value.absent(),
    Value<String?> ttsEngine = const Value.absent(),
    Value<String?> reviewJson = const Value.absent(),
    Value<double?> costEstimate = const Value.absent(),
  }) => Session(
    id: id ?? this.id,
    scenarioId: scenarioId.present ? scenarioId.value : this.scenarioId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    durationSec: durationSec ?? this.durationSec,
    turnCount: turnCount ?? this.turnCount,
    hintCount: hintCount ?? this.hintCount,
    assistTurns: assistTurns ?? this.assistTurns,
    translateCount: translateCount ?? this.translateCount,
    status: status ?? this.status,
    modelName: modelName.present ? modelName.value : this.modelName,
    ttsEngine: ttsEngine.present ? ttsEngine.value : this.ttsEngine,
    reviewJson: reviewJson.present ? reviewJson.value : this.reviewJson,
    costEstimate: costEstimate.present ? costEstimate.value : this.costEstimate,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      scenarioId: data.scenarioId.present
          ? data.scenarioId.value
          : this.scenarioId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      turnCount: data.turnCount.present ? data.turnCount.value : this.turnCount,
      hintCount: data.hintCount.present ? data.hintCount.value : this.hintCount,
      assistTurns: data.assistTurns.present
          ? data.assistTurns.value
          : this.assistTurns,
      translateCount: data.translateCount.present
          ? data.translateCount.value
          : this.translateCount,
      status: data.status.present ? data.status.value : this.status,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      ttsEngine: data.ttsEngine.present ? data.ttsEngine.value : this.ttsEngine,
      reviewJson: data.reviewJson.present
          ? data.reviewJson.value
          : this.reviewJson,
      costEstimate: data.costEstimate.present
          ? data.costEstimate.value
          : this.costEstimate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('scenarioId: $scenarioId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSec: $durationSec, ')
          ..write('turnCount: $turnCount, ')
          ..write('hintCount: $hintCount, ')
          ..write('assistTurns: $assistTurns, ')
          ..write('translateCount: $translateCount, ')
          ..write('status: $status, ')
          ..write('modelName: $modelName, ')
          ..write('ttsEngine: $ttsEngine, ')
          ..write('reviewJson: $reviewJson, ')
          ..write('costEstimate: $costEstimate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scenarioId,
    startedAt,
    endedAt,
    durationSec,
    turnCount,
    hintCount,
    assistTurns,
    translateCount,
    status,
    modelName,
    ttsEngine,
    reviewJson,
    costEstimate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.scenarioId == this.scenarioId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationSec == this.durationSec &&
          other.turnCount == this.turnCount &&
          other.hintCount == this.hintCount &&
          other.assistTurns == this.assistTurns &&
          other.translateCount == this.translateCount &&
          other.status == this.status &&
          other.modelName == this.modelName &&
          other.ttsEngine == this.ttsEngine &&
          other.reviewJson == this.reviewJson &&
          other.costEstimate == this.costEstimate);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<String?> scenarioId;
  final Value<int> startedAt;
  final Value<int?> endedAt;
  final Value<int> durationSec;
  final Value<int> turnCount;
  final Value<int> hintCount;
  final Value<int> assistTurns;
  final Value<int> translateCount;
  final Value<String> status;
  final Value<String?> modelName;
  final Value<String?> ttsEngine;
  final Value<String?> reviewJson;
  final Value<double?> costEstimate;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.scenarioId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.turnCount = const Value.absent(),
    this.hintCount = const Value.absent(),
    this.assistTurns = const Value.absent(),
    this.translateCount = const Value.absent(),
    this.status = const Value.absent(),
    this.modelName = const Value.absent(),
    this.ttsEngine = const Value.absent(),
    this.reviewJson = const Value.absent(),
    this.costEstimate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    this.scenarioId = const Value.absent(),
    required int startedAt,
    this.endedAt = const Value.absent(),
    required int durationSec,
    required int turnCount,
    required int hintCount,
    required int assistTurns,
    required int translateCount,
    required String status,
    this.modelName = const Value.absent(),
    this.ttsEngine = const Value.absent(),
    this.reviewJson = const Value.absent(),
    this.costEstimate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       durationSec = Value(durationSec),
       turnCount = Value(turnCount),
       hintCount = Value(hintCount),
       assistTurns = Value(assistTurns),
       translateCount = Value(translateCount),
       status = Value(status);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<String>? scenarioId,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<int>? durationSec,
    Expression<int>? turnCount,
    Expression<int>? hintCount,
    Expression<int>? assistTurns,
    Expression<int>? translateCount,
    Expression<String>? status,
    Expression<String>? modelName,
    Expression<String>? ttsEngine,
    Expression<String>? reviewJson,
    Expression<double>? costEstimate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scenarioId != null) 'scenario_id': scenarioId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationSec != null) 'duration_sec': durationSec,
      if (turnCount != null) 'turn_count': turnCount,
      if (hintCount != null) 'hint_count': hintCount,
      if (assistTurns != null) 'assist_turns': assistTurns,
      if (translateCount != null) 'translate_count': translateCount,
      if (status != null) 'status': status,
      if (modelName != null) 'model_name': modelName,
      if (ttsEngine != null) 'tts_engine': ttsEngine,
      if (reviewJson != null) 'review_json': reviewJson,
      if (costEstimate != null) 'cost_estimate': costEstimate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? scenarioId,
    Value<int>? startedAt,
    Value<int?>? endedAt,
    Value<int>? durationSec,
    Value<int>? turnCount,
    Value<int>? hintCount,
    Value<int>? assistTurns,
    Value<int>? translateCount,
    Value<String>? status,
    Value<String?>? modelName,
    Value<String?>? ttsEngine,
    Value<String?>? reviewJson,
    Value<double?>? costEstimate,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      scenarioId: scenarioId ?? this.scenarioId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSec: durationSec ?? this.durationSec,
      turnCount: turnCount ?? this.turnCount,
      hintCount: hintCount ?? this.hintCount,
      assistTurns: assistTurns ?? this.assistTurns,
      translateCount: translateCount ?? this.translateCount,
      status: status ?? this.status,
      modelName: modelName ?? this.modelName,
      ttsEngine: ttsEngine ?? this.ttsEngine,
      reviewJson: reviewJson ?? this.reviewJson,
      costEstimate: costEstimate ?? this.costEstimate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scenarioId.present) {
      map['scenario_id'] = Variable<String>(scenarioId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (turnCount.present) {
      map['turn_count'] = Variable<int>(turnCount.value);
    }
    if (hintCount.present) {
      map['hint_count'] = Variable<int>(hintCount.value);
    }
    if (assistTurns.present) {
      map['assist_turns'] = Variable<int>(assistTurns.value);
    }
    if (translateCount.present) {
      map['translate_count'] = Variable<int>(translateCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (ttsEngine.present) {
      map['tts_engine'] = Variable<String>(ttsEngine.value);
    }
    if (reviewJson.present) {
      map['review_json'] = Variable<String>(reviewJson.value);
    }
    if (costEstimate.present) {
      map['cost_estimate'] = Variable<double>(costEstimate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('scenarioId: $scenarioId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSec: $durationSec, ')
          ..write('turnCount: $turnCount, ')
          ..write('hintCount: $hintCount, ')
          ..write('assistTurns: $assistTurns, ')
          ..write('translateCount: $translateCount, ')
          ..write('status: $status, ')
          ..write('modelName: $modelName, ')
          ..write('ttsEngine: $ttsEngine, ')
          ..write('reviewJson: $reviewJson, ')
          ..write('costEstimate: $costEstimate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textEnMeta = const VerificationMeta('textEn');
  @override
  late final GeneratedColumn<String> textEn = GeneratedColumn<String>(
    'text_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textZhMeta = const VerificationMeta('textZh');
  @override
  late final GeneratedColumn<String> textZh = GeneratedColumn<String>(
    'text_zh',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioPathMeta = const VerificationMeta(
    'audioPath',
  );
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
    'audio_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _asrProviderMeta = const VerificationMeta(
    'asrProvider',
  );
  @override
  late final GeneratedColumn<String> asrProvider = GeneratedColumn<String>(
    'asr_provider',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latencyMsMeta = const VerificationMeta(
    'latencyMs',
  );
  @override
  late final GeneratedColumn<int> latencyMs = GeneratedColumn<int>(
    'latency_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isHintMeta = const VerificationMeta('isHint');
  @override
  late final GeneratedColumn<int> isHint = GeneratedColumn<int>(
    'is_hint',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintLevelMeta = const VerificationMeta(
    'hintLevel',
  );
  @override
  late final GeneratedColumn<int> hintLevel = GeneratedColumn<int>(
    'hint_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    seq,
    role,
    textEn,
    textZh,
    audioPath,
    asrProvider,
    latencyMs,
    isHint,
    hintLevel,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('text_en')) {
      context.handle(
        _textEnMeta,
        textEn.isAcceptableOrUnknown(data['text_en']!, _textEnMeta),
      );
    } else if (isInserting) {
      context.missing(_textEnMeta);
    }
    if (data.containsKey('text_zh')) {
      context.handle(
        _textZhMeta,
        textZh.isAcceptableOrUnknown(data['text_zh']!, _textZhMeta),
      );
    }
    if (data.containsKey('audio_path')) {
      context.handle(
        _audioPathMeta,
        audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta),
      );
    }
    if (data.containsKey('asr_provider')) {
      context.handle(
        _asrProviderMeta,
        asrProvider.isAcceptableOrUnknown(
          data['asr_provider']!,
          _asrProviderMeta,
        ),
      );
    }
    if (data.containsKey('latency_ms')) {
      context.handle(
        _latencyMsMeta,
        latencyMs.isAcceptableOrUnknown(data['latency_ms']!, _latencyMsMeta),
      );
    }
    if (data.containsKey('is_hint')) {
      context.handle(
        _isHintMeta,
        isHint.isAcceptableOrUnknown(data['is_hint']!, _isHintMeta),
      );
    } else if (isInserting) {
      context.missing(_isHintMeta);
    }
    if (data.containsKey('hint_level')) {
      context.handle(
        _hintLevelMeta,
        hintLevel.isAcceptableOrUnknown(data['hint_level']!, _hintLevelMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      textEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_en'],
      )!,
      textZh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_zh'],
      ),
      audioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_path'],
      ),
      asrProvider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asr_provider'],
      ),
      latencyMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latency_ms'],
      ),
      isHint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_hint'],
      )!,
      hintLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hint_level'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final String id;
  final String sessionId;
  final int seq;
  final String role;
  final String textEn;
  final String? textZh;
  final String? audioPath;
  final String? asrProvider;
  final int? latencyMs;
  final int isHint;
  final int? hintLevel;
  final String status;
  final int createdAt;
  const Message({
    required this.id,
    required this.sessionId,
    required this.seq,
    required this.role,
    required this.textEn,
    this.textZh,
    this.audioPath,
    this.asrProvider,
    this.latencyMs,
    required this.isHint,
    this.hintLevel,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['seq'] = Variable<int>(seq);
    map['role'] = Variable<String>(role);
    map['text_en'] = Variable<String>(textEn);
    if (!nullToAbsent || textZh != null) {
      map['text_zh'] = Variable<String>(textZh);
    }
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    if (!nullToAbsent || asrProvider != null) {
      map['asr_provider'] = Variable<String>(asrProvider);
    }
    if (!nullToAbsent || latencyMs != null) {
      map['latency_ms'] = Variable<int>(latencyMs);
    }
    map['is_hint'] = Variable<int>(isHint);
    if (!nullToAbsent || hintLevel != null) {
      map['hint_level'] = Variable<int>(hintLevel);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      seq: Value(seq),
      role: Value(role),
      textEn: Value(textEn),
      textZh: textZh == null && nullToAbsent
          ? const Value.absent()
          : Value(textZh),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      asrProvider: asrProvider == null && nullToAbsent
          ? const Value.absent()
          : Value(asrProvider),
      latencyMs: latencyMs == null && nullToAbsent
          ? const Value.absent()
          : Value(latencyMs),
      isHint: Value(isHint),
      hintLevel: hintLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(hintLevel),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      seq: serializer.fromJson<int>(json['seq']),
      role: serializer.fromJson<String>(json['role']),
      textEn: serializer.fromJson<String>(json['textEn']),
      textZh: serializer.fromJson<String?>(json['textZh']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      asrProvider: serializer.fromJson<String?>(json['asrProvider']),
      latencyMs: serializer.fromJson<int?>(json['latencyMs']),
      isHint: serializer.fromJson<int>(json['isHint']),
      hintLevel: serializer.fromJson<int?>(json['hintLevel']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'seq': serializer.toJson<int>(seq),
      'role': serializer.toJson<String>(role),
      'textEn': serializer.toJson<String>(textEn),
      'textZh': serializer.toJson<String?>(textZh),
      'audioPath': serializer.toJson<String?>(audioPath),
      'asrProvider': serializer.toJson<String?>(asrProvider),
      'latencyMs': serializer.toJson<int?>(latencyMs),
      'isHint': serializer.toJson<int>(isHint),
      'hintLevel': serializer.toJson<int?>(hintLevel),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Message copyWith({
    String? id,
    String? sessionId,
    int? seq,
    String? role,
    String? textEn,
    Value<String?> textZh = const Value.absent(),
    Value<String?> audioPath = const Value.absent(),
    Value<String?> asrProvider = const Value.absent(),
    Value<int?> latencyMs = const Value.absent(),
    int? isHint,
    Value<int?> hintLevel = const Value.absent(),
    String? status,
    int? createdAt,
  }) => Message(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    seq: seq ?? this.seq,
    role: role ?? this.role,
    textEn: textEn ?? this.textEn,
    textZh: textZh.present ? textZh.value : this.textZh,
    audioPath: audioPath.present ? audioPath.value : this.audioPath,
    asrProvider: asrProvider.present ? asrProvider.value : this.asrProvider,
    latencyMs: latencyMs.present ? latencyMs.value : this.latencyMs,
    isHint: isHint ?? this.isHint,
    hintLevel: hintLevel.present ? hintLevel.value : this.hintLevel,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      seq: data.seq.present ? data.seq.value : this.seq,
      role: data.role.present ? data.role.value : this.role,
      textEn: data.textEn.present ? data.textEn.value : this.textEn,
      textZh: data.textZh.present ? data.textZh.value : this.textZh,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      asrProvider: data.asrProvider.present
          ? data.asrProvider.value
          : this.asrProvider,
      latencyMs: data.latencyMs.present ? data.latencyMs.value : this.latencyMs,
      isHint: data.isHint.present ? data.isHint.value : this.isHint,
      hintLevel: data.hintLevel.present ? data.hintLevel.value : this.hintLevel,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('role: $role, ')
          ..write('textEn: $textEn, ')
          ..write('textZh: $textZh, ')
          ..write('audioPath: $audioPath, ')
          ..write('asrProvider: $asrProvider, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('isHint: $isHint, ')
          ..write('hintLevel: $hintLevel, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    seq,
    role,
    textEn,
    textZh,
    audioPath,
    asrProvider,
    latencyMs,
    isHint,
    hintLevel,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.seq == this.seq &&
          other.role == this.role &&
          other.textEn == this.textEn &&
          other.textZh == this.textZh &&
          other.audioPath == this.audioPath &&
          other.asrProvider == this.asrProvider &&
          other.latencyMs == this.latencyMs &&
          other.isHint == this.isHint &&
          other.hintLevel == this.hintLevel &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> seq;
  final Value<String> role;
  final Value<String> textEn;
  final Value<String?> textZh;
  final Value<String?> audioPath;
  final Value<String?> asrProvider;
  final Value<int?> latencyMs;
  final Value<int> isHint;
  final Value<int?> hintLevel;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.seq = const Value.absent(),
    this.role = const Value.absent(),
    this.textEn = const Value.absent(),
    this.textZh = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.asrProvider = const Value.absent(),
    this.latencyMs = const Value.absent(),
    this.isHint = const Value.absent(),
    this.hintLevel = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String sessionId,
    required int seq,
    required String role,
    required String textEn,
    this.textZh = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.asrProvider = const Value.absent(),
    this.latencyMs = const Value.absent(),
    required int isHint,
    this.hintLevel = const Value.absent(),
    required String status,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       seq = Value(seq),
       role = Value(role),
       textEn = Value(textEn),
       isHint = Value(isHint),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<Message> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? seq,
    Expression<String>? role,
    Expression<String>? textEn,
    Expression<String>? textZh,
    Expression<String>? audioPath,
    Expression<String>? asrProvider,
    Expression<int>? latencyMs,
    Expression<int>? isHint,
    Expression<int>? hintLevel,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (seq != null) 'seq': seq,
      if (role != null) 'role': role,
      if (textEn != null) 'text_en': textEn,
      if (textZh != null) 'text_zh': textZh,
      if (audioPath != null) 'audio_path': audioPath,
      if (asrProvider != null) 'asr_provider': asrProvider,
      if (latencyMs != null) 'latency_ms': latencyMs,
      if (isHint != null) 'is_hint': isHint,
      if (hintLevel != null) 'hint_level': hintLevel,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? seq,
    Value<String>? role,
    Value<String>? textEn,
    Value<String?>? textZh,
    Value<String?>? audioPath,
    Value<String?>? asrProvider,
    Value<int?>? latencyMs,
    Value<int>? isHint,
    Value<int?>? hintLevel,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      seq: seq ?? this.seq,
      role: role ?? this.role,
      textEn: textEn ?? this.textEn,
      textZh: textZh ?? this.textZh,
      audioPath: audioPath ?? this.audioPath,
      asrProvider: asrProvider ?? this.asrProvider,
      latencyMs: latencyMs ?? this.latencyMs,
      isHint: isHint ?? this.isHint,
      hintLevel: hintLevel ?? this.hintLevel,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (textEn.present) {
      map['text_en'] = Variable<String>(textEn.value);
    }
    if (textZh.present) {
      map['text_zh'] = Variable<String>(textZh.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (asrProvider.present) {
      map['asr_provider'] = Variable<String>(asrProvider.value);
    }
    if (latencyMs.present) {
      map['latency_ms'] = Variable<int>(latencyMs.value);
    }
    if (isHint.present) {
      map['is_hint'] = Variable<int>(isHint.value);
    }
    if (hintLevel.present) {
      map['hint_level'] = Variable<int>(hintLevel.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('role: $role, ')
          ..write('textEn: $textEn, ')
          ..write('textZh: $textZh, ')
          ..write('audioPath: $audioPath, ')
          ..write('asrProvider: $asrProvider, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('isHint: $isHint, ')
          ..write('hintLevel: $hintLevel, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CorrectionsTable extends Corrections
    with TableInfo<$CorrectionsTable, Correction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CorrectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalMeta = const VerificationMeta(
    'original',
  );
  @override
  late final GeneratedColumn<String> original = GeneratedColumn<String>(
    'original',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _improvedMeta = const VerificationMeta(
    'improved',
  );
  @override
  late final GeneratedColumn<String> improved = GeneratedColumn<String>(
    'improved',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonZhMeta = const VerificationMeta(
    'reasonZh',
  );
  @override
  late final GeneratedColumn<String> reasonZh = GeneratedColumn<String>(
    'reason_zh',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioPathMeta = const VerificationMeta(
    'audioPath',
  );
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
    'audio_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    messageId,
    original,
    improved,
    reasonZh,
    audioPath,
    isDeleted,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'correction';
  @override
  VerificationContext validateIntegrity(
    Insertable<Correction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('original')) {
      context.handle(
        _originalMeta,
        original.isAcceptableOrUnknown(data['original']!, _originalMeta),
      );
    } else if (isInserting) {
      context.missing(_originalMeta);
    }
    if (data.containsKey('improved')) {
      context.handle(
        _improvedMeta,
        improved.isAcceptableOrUnknown(data['improved']!, _improvedMeta),
      );
    } else if (isInserting) {
      context.missing(_improvedMeta);
    }
    if (data.containsKey('reason_zh')) {
      context.handle(
        _reasonZhMeta,
        reasonZh.isAcceptableOrUnknown(data['reason_zh']!, _reasonZhMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonZhMeta);
    }
    if (data.containsKey('audio_path')) {
      context.handle(
        _audioPathMeta,
        audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    } else if (isInserting) {
      context.missing(_isDeletedMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Correction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Correction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      original: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original'],
      )!,
      improved: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}improved'],
      )!,
      reasonZh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_zh'],
      )!,
      audioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_path'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CorrectionsTable createAlias(String alias) {
    return $CorrectionsTable(attachedDatabase, alias);
  }
}

class Correction extends DataClass implements Insertable<Correction> {
  final String id;
  final String sessionId;
  final String messageId;
  final String original;
  final String improved;
  final String reasonZh;
  final String? audioPath;
  final int isDeleted;
  final int createdAt;
  const Correction({
    required this.id,
    required this.sessionId,
    required this.messageId,
    required this.original,
    required this.improved,
    required this.reasonZh,
    this.audioPath,
    required this.isDeleted,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['message_id'] = Variable<String>(messageId);
    map['original'] = Variable<String>(original);
    map['improved'] = Variable<String>(improved);
    map['reason_zh'] = Variable<String>(reasonZh);
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    map['is_deleted'] = Variable<int>(isDeleted);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CorrectionsCompanion toCompanion(bool nullToAbsent) {
    return CorrectionsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      messageId: Value(messageId),
      original: Value(original),
      improved: Value(improved),
      reasonZh: Value(reasonZh),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
    );
  }

  factory Correction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Correction(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      messageId: serializer.fromJson<String>(json['messageId']),
      original: serializer.fromJson<String>(json['original']),
      improved: serializer.fromJson<String>(json['improved']),
      reasonZh: serializer.fromJson<String>(json['reasonZh']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'messageId': serializer.toJson<String>(messageId),
      'original': serializer.toJson<String>(original),
      'improved': serializer.toJson<String>(improved),
      'reasonZh': serializer.toJson<String>(reasonZh),
      'audioPath': serializer.toJson<String?>(audioPath),
      'isDeleted': serializer.toJson<int>(isDeleted),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Correction copyWith({
    String? id,
    String? sessionId,
    String? messageId,
    String? original,
    String? improved,
    String? reasonZh,
    Value<String?> audioPath = const Value.absent(),
    int? isDeleted,
    int? createdAt,
  }) => Correction(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    messageId: messageId ?? this.messageId,
    original: original ?? this.original,
    improved: improved ?? this.improved,
    reasonZh: reasonZh ?? this.reasonZh,
    audioPath: audioPath.present ? audioPath.value : this.audioPath,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
  );
  Correction copyWithCompanion(CorrectionsCompanion data) {
    return Correction(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      original: data.original.present ? data.original.value : this.original,
      improved: data.improved.present ? data.improved.value : this.improved,
      reasonZh: data.reasonZh.present ? data.reasonZh.value : this.reasonZh,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Correction(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('messageId: $messageId, ')
          ..write('original: $original, ')
          ..write('improved: $improved, ')
          ..write('reasonZh: $reasonZh, ')
          ..write('audioPath: $audioPath, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    messageId,
    original,
    improved,
    reasonZh,
    audioPath,
    isDeleted,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Correction &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.messageId == this.messageId &&
          other.original == this.original &&
          other.improved == this.improved &&
          other.reasonZh == this.reasonZh &&
          other.audioPath == this.audioPath &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt);
}

class CorrectionsCompanion extends UpdateCompanion<Correction> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> messageId;
  final Value<String> original;
  final Value<String> improved;
  final Value<String> reasonZh;
  final Value<String?> audioPath;
  final Value<int> isDeleted;
  final Value<int> createdAt;
  final Value<int> rowid;
  const CorrectionsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.original = const Value.absent(),
    this.improved = const Value.absent(),
    this.reasonZh = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CorrectionsCompanion.insert({
    required String id,
    required String sessionId,
    required String messageId,
    required String original,
    required String improved,
    required String reasonZh,
    this.audioPath = const Value.absent(),
    required int isDeleted,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       messageId = Value(messageId),
       original = Value(original),
       improved = Value(improved),
       reasonZh = Value(reasonZh),
       isDeleted = Value(isDeleted),
       createdAt = Value(createdAt);
  static Insertable<Correction> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? messageId,
    Expression<String>? original,
    Expression<String>? improved,
    Expression<String>? reasonZh,
    Expression<String>? audioPath,
    Expression<int>? isDeleted,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (messageId != null) 'message_id': messageId,
      if (original != null) 'original': original,
      if (improved != null) 'improved': improved,
      if (reasonZh != null) 'reason_zh': reasonZh,
      if (audioPath != null) 'audio_path': audioPath,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CorrectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? messageId,
    Value<String>? original,
    Value<String>? improved,
    Value<String>? reasonZh,
    Value<String?>? audioPath,
    Value<int>? isDeleted,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return CorrectionsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      messageId: messageId ?? this.messageId,
      original: original ?? this.original,
      improved: improved ?? this.improved,
      reasonZh: reasonZh ?? this.reasonZh,
      audioPath: audioPath ?? this.audioPath,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (original.present) {
      map['original'] = Variable<String>(original.value);
    }
    if (improved.present) {
      map['improved'] = Variable<String>(improved.value);
    }
    if (reasonZh.present) {
      map['reason_zh'] = Variable<String>(reasonZh.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CorrectionsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('messageId: $messageId, ')
          ..write('original: $original, ')
          ..write('improved: $improved, ')
          ..write('reasonZh: $reasonZh, ')
          ..write('audioPath: $audioPath, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhrasesTable extends Phrases with TableInfo<$PhrasesTable, Phrase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhrasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textEnMeta = const VerificationMeta('textEn');
  @override
  late final GeneratedColumn<String> textEn = GeneratedColumn<String>(
    'text_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textZhMeta = const VerificationMeta('textZh');
  @override
  late final GeneratedColumn<String> textZh = GeneratedColumn<String>(
    'text_zh',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceSessionIdMeta = const VerificationMeta(
    'sourceSessionId',
  );
  @override
  late final GeneratedColumn<String> sourceSessionId = GeneratedColumn<String>(
    'source_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceScenarioIdMeta = const VerificationMeta(
    'sourceScenarioId',
  );
  @override
  late final GeneratedColumn<String> sourceScenarioId = GeneratedColumn<String>(
    'source_scenario_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioPathMeta = const VerificationMeta(
    'audioPath',
  );
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
    'audio_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _masteredMeta = const VerificationMeta(
    'mastered',
  );
  @override
  late final GeneratedColumn<int> mastered = GeneratedColumn<int>(
    'mastered',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    textEn,
    textZh,
    sourceSessionId,
    sourceScenarioId,
    audioPath,
    mastered,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'phrase';
  @override
  VerificationContext validateIntegrity(
    Insertable<Phrase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('text_en')) {
      context.handle(
        _textEnMeta,
        textEn.isAcceptableOrUnknown(data['text_en']!, _textEnMeta),
      );
    } else if (isInserting) {
      context.missing(_textEnMeta);
    }
    if (data.containsKey('text_zh')) {
      context.handle(
        _textZhMeta,
        textZh.isAcceptableOrUnknown(data['text_zh']!, _textZhMeta),
      );
    }
    if (data.containsKey('source_session_id')) {
      context.handle(
        _sourceSessionIdMeta,
        sourceSessionId.isAcceptableOrUnknown(
          data['source_session_id']!,
          _sourceSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('source_scenario_id')) {
      context.handle(
        _sourceScenarioIdMeta,
        sourceScenarioId.isAcceptableOrUnknown(
          data['source_scenario_id']!,
          _sourceScenarioIdMeta,
        ),
      );
    }
    if (data.containsKey('audio_path')) {
      context.handle(
        _audioPathMeta,
        audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta),
      );
    }
    if (data.containsKey('mastered')) {
      context.handle(
        _masteredMeta,
        mastered.isAcceptableOrUnknown(data['mastered']!, _masteredMeta),
      );
    } else if (isInserting) {
      context.missing(_masteredMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Phrase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Phrase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      textEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_en'],
      )!,
      textZh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_zh'],
      ),
      sourceSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_session_id'],
      ),
      sourceScenarioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_scenario_id'],
      ),
      audioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_path'],
      ),
      mastered: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mastered'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PhrasesTable createAlias(String alias) {
    return $PhrasesTable(attachedDatabase, alias);
  }
}

class Phrase extends DataClass implements Insertable<Phrase> {
  final String id;
  final String textEn;
  final String? textZh;
  final String? sourceSessionId;
  final String? sourceScenarioId;
  final String? audioPath;
  final int mastered;
  final int createdAt;
  const Phrase({
    required this.id,
    required this.textEn,
    this.textZh,
    this.sourceSessionId,
    this.sourceScenarioId,
    this.audioPath,
    required this.mastered,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['text_en'] = Variable<String>(textEn);
    if (!nullToAbsent || textZh != null) {
      map['text_zh'] = Variable<String>(textZh);
    }
    if (!nullToAbsent || sourceSessionId != null) {
      map['source_session_id'] = Variable<String>(sourceSessionId);
    }
    if (!nullToAbsent || sourceScenarioId != null) {
      map['source_scenario_id'] = Variable<String>(sourceScenarioId);
    }
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    map['mastered'] = Variable<int>(mastered);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PhrasesCompanion toCompanion(bool nullToAbsent) {
    return PhrasesCompanion(
      id: Value(id),
      textEn: Value(textEn),
      textZh: textZh == null && nullToAbsent
          ? const Value.absent()
          : Value(textZh),
      sourceSessionId: sourceSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceSessionId),
      sourceScenarioId: sourceScenarioId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceScenarioId),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      mastered: Value(mastered),
      createdAt: Value(createdAt),
    );
  }

  factory Phrase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Phrase(
      id: serializer.fromJson<String>(json['id']),
      textEn: serializer.fromJson<String>(json['textEn']),
      textZh: serializer.fromJson<String?>(json['textZh']),
      sourceSessionId: serializer.fromJson<String?>(json['sourceSessionId']),
      sourceScenarioId: serializer.fromJson<String?>(json['sourceScenarioId']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      mastered: serializer.fromJson<int>(json['mastered']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'textEn': serializer.toJson<String>(textEn),
      'textZh': serializer.toJson<String?>(textZh),
      'sourceSessionId': serializer.toJson<String?>(sourceSessionId),
      'sourceScenarioId': serializer.toJson<String?>(sourceScenarioId),
      'audioPath': serializer.toJson<String?>(audioPath),
      'mastered': serializer.toJson<int>(mastered),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Phrase copyWith({
    String? id,
    String? textEn,
    Value<String?> textZh = const Value.absent(),
    Value<String?> sourceSessionId = const Value.absent(),
    Value<String?> sourceScenarioId = const Value.absent(),
    Value<String?> audioPath = const Value.absent(),
    int? mastered,
    int? createdAt,
  }) => Phrase(
    id: id ?? this.id,
    textEn: textEn ?? this.textEn,
    textZh: textZh.present ? textZh.value : this.textZh,
    sourceSessionId: sourceSessionId.present
        ? sourceSessionId.value
        : this.sourceSessionId,
    sourceScenarioId: sourceScenarioId.present
        ? sourceScenarioId.value
        : this.sourceScenarioId,
    audioPath: audioPath.present ? audioPath.value : this.audioPath,
    mastered: mastered ?? this.mastered,
    createdAt: createdAt ?? this.createdAt,
  );
  Phrase copyWithCompanion(PhrasesCompanion data) {
    return Phrase(
      id: data.id.present ? data.id.value : this.id,
      textEn: data.textEn.present ? data.textEn.value : this.textEn,
      textZh: data.textZh.present ? data.textZh.value : this.textZh,
      sourceSessionId: data.sourceSessionId.present
          ? data.sourceSessionId.value
          : this.sourceSessionId,
      sourceScenarioId: data.sourceScenarioId.present
          ? data.sourceScenarioId.value
          : this.sourceScenarioId,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      mastered: data.mastered.present ? data.mastered.value : this.mastered,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Phrase(')
          ..write('id: $id, ')
          ..write('textEn: $textEn, ')
          ..write('textZh: $textZh, ')
          ..write('sourceSessionId: $sourceSessionId, ')
          ..write('sourceScenarioId: $sourceScenarioId, ')
          ..write('audioPath: $audioPath, ')
          ..write('mastered: $mastered, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    textEn,
    textZh,
    sourceSessionId,
    sourceScenarioId,
    audioPath,
    mastered,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Phrase &&
          other.id == this.id &&
          other.textEn == this.textEn &&
          other.textZh == this.textZh &&
          other.sourceSessionId == this.sourceSessionId &&
          other.sourceScenarioId == this.sourceScenarioId &&
          other.audioPath == this.audioPath &&
          other.mastered == this.mastered &&
          other.createdAt == this.createdAt);
}

class PhrasesCompanion extends UpdateCompanion<Phrase> {
  final Value<String> id;
  final Value<String> textEn;
  final Value<String?> textZh;
  final Value<String?> sourceSessionId;
  final Value<String?> sourceScenarioId;
  final Value<String?> audioPath;
  final Value<int> mastered;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PhrasesCompanion({
    this.id = const Value.absent(),
    this.textEn = const Value.absent(),
    this.textZh = const Value.absent(),
    this.sourceSessionId = const Value.absent(),
    this.sourceScenarioId = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.mastered = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhrasesCompanion.insert({
    required String id,
    required String textEn,
    this.textZh = const Value.absent(),
    this.sourceSessionId = const Value.absent(),
    this.sourceScenarioId = const Value.absent(),
    this.audioPath = const Value.absent(),
    required int mastered,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       textEn = Value(textEn),
       mastered = Value(mastered),
       createdAt = Value(createdAt);
  static Insertable<Phrase> custom({
    Expression<String>? id,
    Expression<String>? textEn,
    Expression<String>? textZh,
    Expression<String>? sourceSessionId,
    Expression<String>? sourceScenarioId,
    Expression<String>? audioPath,
    Expression<int>? mastered,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (textEn != null) 'text_en': textEn,
      if (textZh != null) 'text_zh': textZh,
      if (sourceSessionId != null) 'source_session_id': sourceSessionId,
      if (sourceScenarioId != null) 'source_scenario_id': sourceScenarioId,
      if (audioPath != null) 'audio_path': audioPath,
      if (mastered != null) 'mastered': mastered,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhrasesCompanion copyWith({
    Value<String>? id,
    Value<String>? textEn,
    Value<String?>? textZh,
    Value<String?>? sourceSessionId,
    Value<String?>? sourceScenarioId,
    Value<String?>? audioPath,
    Value<int>? mastered,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return PhrasesCompanion(
      id: id ?? this.id,
      textEn: textEn ?? this.textEn,
      textZh: textZh ?? this.textZh,
      sourceSessionId: sourceSessionId ?? this.sourceSessionId,
      sourceScenarioId: sourceScenarioId ?? this.sourceScenarioId,
      audioPath: audioPath ?? this.audioPath,
      mastered: mastered ?? this.mastered,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (textEn.present) {
      map['text_en'] = Variable<String>(textEn.value);
    }
    if (textZh.present) {
      map['text_zh'] = Variable<String>(textZh.value);
    }
    if (sourceSessionId.present) {
      map['source_session_id'] = Variable<String>(sourceSessionId.value);
    }
    if (sourceScenarioId.present) {
      map['source_scenario_id'] = Variable<String>(sourceScenarioId.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (mastered.present) {
      map['mastered'] = Variable<int>(mastered.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhrasesCompanion(')
          ..write('id: $id, ')
          ..write('textEn: $textEn, ')
          ..write('textZh: $textZh, ')
          ..write('sourceSessionId: $sourceSessionId, ')
          ..write('sourceScenarioId: $sourceScenarioId, ')
          ..write('audioPath: $audioPath, ')
          ..write('mastered: $mastered, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LlmProfilesTable extends LlmProfiles
    with TableInfo<$LlmProfilesTable, LlmProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LlmProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyRefMeta = const VerificationMeta('keyRef');
  @override
  late final GeneratedColumn<String> keyRef = GeneratedColumn<String>(
    'key_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extraJsonMeta = const VerificationMeta(
    'extraJson',
  );
  @override
  late final GeneratedColumn<String> extraJson = GeneratedColumn<String>(
    'extra_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastCheckStatusMeta = const VerificationMeta(
    'lastCheckStatus',
  );
  @override
  late final GeneratedColumn<String> lastCheckStatus = GeneratedColumn<String>(
    'last_check_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastCheckMessageMeta = const VerificationMeta(
    'lastCheckMessage',
  );
  @override
  late final GeneratedColumn<String> lastCheckMessage = GeneratedColumn<String>(
    'last_check_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastCheckedAtMeta = const VerificationMeta(
    'lastCheckedAt',
  );
  @override
  late final GeneratedColumn<int> lastCheckedAt = GeneratedColumn<int>(
    'last_checked_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<int> isActive = GeneratedColumn<int>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    baseUrl,
    model,
    keyRef,
    extraJson,
    lastCheckStatus,
    lastCheckMessage,
    lastCheckedAt,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'llm_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<LlmProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('key_ref')) {
      context.handle(
        _keyRefMeta,
        keyRef.isAcceptableOrUnknown(data['key_ref']!, _keyRefMeta),
      );
    } else if (isInserting) {
      context.missing(_keyRefMeta);
    }
    if (data.containsKey('extra_json')) {
      context.handle(
        _extraJsonMeta,
        extraJson.isAcceptableOrUnknown(data['extra_json']!, _extraJsonMeta),
      );
    }
    if (data.containsKey('last_check_status')) {
      context.handle(
        _lastCheckStatusMeta,
        lastCheckStatus.isAcceptableOrUnknown(
          data['last_check_status']!,
          _lastCheckStatusMeta,
        ),
      );
    }
    if (data.containsKey('last_check_message')) {
      context.handle(
        _lastCheckMessageMeta,
        lastCheckMessage.isAcceptableOrUnknown(
          data['last_check_message']!,
          _lastCheckMessageMeta,
        ),
      );
    }
    if (data.containsKey('last_checked_at')) {
      context.handle(
        _lastCheckedAtMeta,
        lastCheckedAt.isAcceptableOrUnknown(
          data['last_checked_at']!,
          _lastCheckedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LlmProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LlmProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      keyRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_ref'],
      )!,
      extraJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_json'],
      ),
      lastCheckStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_check_status'],
      ),
      lastCheckMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_check_message'],
      ),
      lastCheckedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_checked_at'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $LlmProfilesTable createAlias(String alias) {
    return $LlmProfilesTable(attachedDatabase, alias);
  }
}

class LlmProfile extends DataClass implements Insertable<LlmProfile> {
  final String id;
  final String name;
  final String baseUrl;
  final String model;
  final String keyRef;
  final String? extraJson;
  final String? lastCheckStatus;
  final String? lastCheckMessage;
  final int? lastCheckedAt;
  final int isActive;
  const LlmProfile({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.model,
    required this.keyRef,
    this.extraJson,
    this.lastCheckStatus,
    this.lastCheckMessage,
    this.lastCheckedAt,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['base_url'] = Variable<String>(baseUrl);
    map['model'] = Variable<String>(model);
    map['key_ref'] = Variable<String>(keyRef);
    if (!nullToAbsent || extraJson != null) {
      map['extra_json'] = Variable<String>(extraJson);
    }
    if (!nullToAbsent || lastCheckStatus != null) {
      map['last_check_status'] = Variable<String>(lastCheckStatus);
    }
    if (!nullToAbsent || lastCheckMessage != null) {
      map['last_check_message'] = Variable<String>(lastCheckMessage);
    }
    if (!nullToAbsent || lastCheckedAt != null) {
      map['last_checked_at'] = Variable<int>(lastCheckedAt);
    }
    map['is_active'] = Variable<int>(isActive);
    return map;
  }

  LlmProfilesCompanion toCompanion(bool nullToAbsent) {
    return LlmProfilesCompanion(
      id: Value(id),
      name: Value(name),
      baseUrl: Value(baseUrl),
      model: Value(model),
      keyRef: Value(keyRef),
      extraJson: extraJson == null && nullToAbsent
          ? const Value.absent()
          : Value(extraJson),
      lastCheckStatus: lastCheckStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckStatus),
      lastCheckMessage: lastCheckMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckMessage),
      lastCheckedAt: lastCheckedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckedAt),
      isActive: Value(isActive),
    );
  }

  factory LlmProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LlmProfile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      model: serializer.fromJson<String>(json['model']),
      keyRef: serializer.fromJson<String>(json['keyRef']),
      extraJson: serializer.fromJson<String?>(json['extraJson']),
      lastCheckStatus: serializer.fromJson<String?>(json['lastCheckStatus']),
      lastCheckMessage: serializer.fromJson<String?>(json['lastCheckMessage']),
      lastCheckedAt: serializer.fromJson<int?>(json['lastCheckedAt']),
      isActive: serializer.fromJson<int>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'model': serializer.toJson<String>(model),
      'keyRef': serializer.toJson<String>(keyRef),
      'extraJson': serializer.toJson<String?>(extraJson),
      'lastCheckStatus': serializer.toJson<String?>(lastCheckStatus),
      'lastCheckMessage': serializer.toJson<String?>(lastCheckMessage),
      'lastCheckedAt': serializer.toJson<int?>(lastCheckedAt),
      'isActive': serializer.toJson<int>(isActive),
    };
  }

  LlmProfile copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? model,
    String? keyRef,
    Value<String?> extraJson = const Value.absent(),
    Value<String?> lastCheckStatus = const Value.absent(),
    Value<String?> lastCheckMessage = const Value.absent(),
    Value<int?> lastCheckedAt = const Value.absent(),
    int? isActive,
  }) => LlmProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    baseUrl: baseUrl ?? this.baseUrl,
    model: model ?? this.model,
    keyRef: keyRef ?? this.keyRef,
    extraJson: extraJson.present ? extraJson.value : this.extraJson,
    lastCheckStatus: lastCheckStatus.present
        ? lastCheckStatus.value
        : this.lastCheckStatus,
    lastCheckMessage: lastCheckMessage.present
        ? lastCheckMessage.value
        : this.lastCheckMessage,
    lastCheckedAt: lastCheckedAt.present
        ? lastCheckedAt.value
        : this.lastCheckedAt,
    isActive: isActive ?? this.isActive,
  );
  LlmProfile copyWithCompanion(LlmProfilesCompanion data) {
    return LlmProfile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      model: data.model.present ? data.model.value : this.model,
      keyRef: data.keyRef.present ? data.keyRef.value : this.keyRef,
      extraJson: data.extraJson.present ? data.extraJson.value : this.extraJson,
      lastCheckStatus: data.lastCheckStatus.present
          ? data.lastCheckStatus.value
          : this.lastCheckStatus,
      lastCheckMessage: data.lastCheckMessage.present
          ? data.lastCheckMessage.value
          : this.lastCheckMessage,
      lastCheckedAt: data.lastCheckedAt.present
          ? data.lastCheckedAt.value
          : this.lastCheckedAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LlmProfile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('model: $model, ')
          ..write('keyRef: $keyRef, ')
          ..write('extraJson: $extraJson, ')
          ..write('lastCheckStatus: $lastCheckStatus, ')
          ..write('lastCheckMessage: $lastCheckMessage, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    baseUrl,
    model,
    keyRef,
    extraJson,
    lastCheckStatus,
    lastCheckMessage,
    lastCheckedAt,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LlmProfile &&
          other.id == this.id &&
          other.name == this.name &&
          other.baseUrl == this.baseUrl &&
          other.model == this.model &&
          other.keyRef == this.keyRef &&
          other.extraJson == this.extraJson &&
          other.lastCheckStatus == this.lastCheckStatus &&
          other.lastCheckMessage == this.lastCheckMessage &&
          other.lastCheckedAt == this.lastCheckedAt &&
          other.isActive == this.isActive);
}

class LlmProfilesCompanion extends UpdateCompanion<LlmProfile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> baseUrl;
  final Value<String> model;
  final Value<String> keyRef;
  final Value<String?> extraJson;
  final Value<String?> lastCheckStatus;
  final Value<String?> lastCheckMessage;
  final Value<int?> lastCheckedAt;
  final Value<int> isActive;
  final Value<int> rowid;
  const LlmProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.model = const Value.absent(),
    this.keyRef = const Value.absent(),
    this.extraJson = const Value.absent(),
    this.lastCheckStatus = const Value.absent(),
    this.lastCheckMessage = const Value.absent(),
    this.lastCheckedAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LlmProfilesCompanion.insert({
    required String id,
    required String name,
    required String baseUrl,
    required String model,
    required String keyRef,
    this.extraJson = const Value.absent(),
    this.lastCheckStatus = const Value.absent(),
    this.lastCheckMessage = const Value.absent(),
    this.lastCheckedAt = const Value.absent(),
    required int isActive,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       baseUrl = Value(baseUrl),
       model = Value(model),
       keyRef = Value(keyRef),
       isActive = Value(isActive);
  static Insertable<LlmProfile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? baseUrl,
    Expression<String>? model,
    Expression<String>? keyRef,
    Expression<String>? extraJson,
    Expression<String>? lastCheckStatus,
    Expression<String>? lastCheckMessage,
    Expression<int>? lastCheckedAt,
    Expression<int>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (baseUrl != null) 'base_url': baseUrl,
      if (model != null) 'model': model,
      if (keyRef != null) 'key_ref': keyRef,
      if (extraJson != null) 'extra_json': extraJson,
      if (lastCheckStatus != null) 'last_check_status': lastCheckStatus,
      if (lastCheckMessage != null) 'last_check_message': lastCheckMessage,
      if (lastCheckedAt != null) 'last_checked_at': lastCheckedAt,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LlmProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? baseUrl,
    Value<String>? model,
    Value<String>? keyRef,
    Value<String?>? extraJson,
    Value<String?>? lastCheckStatus,
    Value<String?>? lastCheckMessage,
    Value<int?>? lastCheckedAt,
    Value<int>? isActive,
    Value<int>? rowid,
  }) {
    return LlmProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      keyRef: keyRef ?? this.keyRef,
      extraJson: extraJson ?? this.extraJson,
      lastCheckStatus: lastCheckStatus ?? this.lastCheckStatus,
      lastCheckMessage: lastCheckMessage ?? this.lastCheckMessage,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (keyRef.present) {
      map['key_ref'] = Variable<String>(keyRef.value);
    }
    if (extraJson.present) {
      map['extra_json'] = Variable<String>(extraJson.value);
    }
    if (lastCheckStatus.present) {
      map['last_check_status'] = Variable<String>(lastCheckStatus.value);
    }
    if (lastCheckMessage.present) {
      map['last_check_message'] = Variable<String>(lastCheckMessage.value);
    }
    if (lastCheckedAt.present) {
      map['last_checked_at'] = Variable<int>(lastCheckedAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<int>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LlmProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('model: $model, ')
          ..write('keyRef: $keyRef, ')
          ..write('extraJson: $extraJson, ')
          ..write('lastCheckStatus: $lastCheckStatus, ')
          ..write('lastCheckMessage: $lastCheckMessage, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsTableData extends DataClass
    implements Insertable<SettingsTableData> {
  final String key;
  final String value;
  final int updatedAt;
  const SettingsTableData({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  SettingsTableData copyWith({String? key, String? value, int? updatedAt}) =>
      SettingsTableData(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SettingsTableData copyWithCompanion(SettingsTableCompanion data) {
    return SettingsTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsTableData &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String key,
    required String value,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<SettingsTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return SettingsTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TtsCachesTable extends TtsCaches
    with TableInfo<$TtsCachesTable, TtsCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TtsCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _engineMeta = const VerificationMeta('engine');
  @override
  late final GeneratedColumn<String> engine = GeneratedColumn<String>(
    'engine',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voiceMeta = const VerificationMeta('voice');
  @override
  late final GeneratedColumn<String> voice = GeneratedColumn<String>(
    'voice',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<int> lastUsedAt = GeneratedColumn<int>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    hash,
    engine,
    voice,
    rate,
    filePath,
    bytes,
    createdAt,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tts_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<TtsCache> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('engine')) {
      context.handle(
        _engineMeta,
        engine.isAcceptableOrUnknown(data['engine']!, _engineMeta),
      );
    } else if (isInserting) {
      context.missing(_engineMeta);
    }
    if (data.containsKey('voice')) {
      context.handle(
        _voiceMeta,
        voice.isAcceptableOrUnknown(data['voice']!, _voiceMeta),
      );
    } else if (isInserting) {
      context.missing(_voiceMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hash};
  @override
  TtsCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TtsCache(
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      engine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}engine'],
      )!,
      voice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice'],
      )!,
      rate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_used_at'],
      )!,
    );
  }

  @override
  $TtsCachesTable createAlias(String alias) {
    return $TtsCachesTable(attachedDatabase, alias);
  }
}

class TtsCache extends DataClass implements Insertable<TtsCache> {
  final String hash;
  final String engine;
  final String voice;
  final double rate;
  final String filePath;
  final int bytes;
  final int createdAt;
  final int lastUsedAt;
  const TtsCache({
    required this.hash,
    required this.engine,
    required this.voice,
    required this.rate,
    required this.filePath,
    required this.bytes,
    required this.createdAt,
    required this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hash'] = Variable<String>(hash);
    map['engine'] = Variable<String>(engine);
    map['voice'] = Variable<String>(voice);
    map['rate'] = Variable<double>(rate);
    map['file_path'] = Variable<String>(filePath);
    map['bytes'] = Variable<int>(bytes);
    map['created_at'] = Variable<int>(createdAt);
    map['last_used_at'] = Variable<int>(lastUsedAt);
    return map;
  }

  TtsCachesCompanion toCompanion(bool nullToAbsent) {
    return TtsCachesCompanion(
      hash: Value(hash),
      engine: Value(engine),
      voice: Value(voice),
      rate: Value(rate),
      filePath: Value(filePath),
      bytes: Value(bytes),
      createdAt: Value(createdAt),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory TtsCache.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TtsCache(
      hash: serializer.fromJson<String>(json['hash']),
      engine: serializer.fromJson<String>(json['engine']),
      voice: serializer.fromJson<String>(json['voice']),
      rate: serializer.fromJson<double>(json['rate']),
      filePath: serializer.fromJson<String>(json['filePath']),
      bytes: serializer.fromJson<int>(json['bytes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastUsedAt: serializer.fromJson<int>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hash': serializer.toJson<String>(hash),
      'engine': serializer.toJson<String>(engine),
      'voice': serializer.toJson<String>(voice),
      'rate': serializer.toJson<double>(rate),
      'filePath': serializer.toJson<String>(filePath),
      'bytes': serializer.toJson<int>(bytes),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastUsedAt': serializer.toJson<int>(lastUsedAt),
    };
  }

  TtsCache copyWith({
    String? hash,
    String? engine,
    String? voice,
    double? rate,
    String? filePath,
    int? bytes,
    int? createdAt,
    int? lastUsedAt,
  }) => TtsCache(
    hash: hash ?? this.hash,
    engine: engine ?? this.engine,
    voice: voice ?? this.voice,
    rate: rate ?? this.rate,
    filePath: filePath ?? this.filePath,
    bytes: bytes ?? this.bytes,
    createdAt: createdAt ?? this.createdAt,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
  TtsCache copyWithCompanion(TtsCachesCompanion data) {
    return TtsCache(
      hash: data.hash.present ? data.hash.value : this.hash,
      engine: data.engine.present ? data.engine.value : this.engine,
      voice: data.voice.present ? data.voice.value : this.voice,
      rate: data.rate.present ? data.rate.value : this.rate,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TtsCache(')
          ..write('hash: $hash, ')
          ..write('engine: $engine, ')
          ..write('voice: $voice, ')
          ..write('rate: $rate, ')
          ..write('filePath: $filePath, ')
          ..write('bytes: $bytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    hash,
    engine,
    voice,
    rate,
    filePath,
    bytes,
    createdAt,
    lastUsedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TtsCache &&
          other.hash == this.hash &&
          other.engine == this.engine &&
          other.voice == this.voice &&
          other.rate == this.rate &&
          other.filePath == this.filePath &&
          other.bytes == this.bytes &&
          other.createdAt == this.createdAt &&
          other.lastUsedAt == this.lastUsedAt);
}

class TtsCachesCompanion extends UpdateCompanion<TtsCache> {
  final Value<String> hash;
  final Value<String> engine;
  final Value<String> voice;
  final Value<double> rate;
  final Value<String> filePath;
  final Value<int> bytes;
  final Value<int> createdAt;
  final Value<int> lastUsedAt;
  final Value<int> rowid;
  const TtsCachesCompanion({
    this.hash = const Value.absent(),
    this.engine = const Value.absent(),
    this.voice = const Value.absent(),
    this.rate = const Value.absent(),
    this.filePath = const Value.absent(),
    this.bytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TtsCachesCompanion.insert({
    required String hash,
    required String engine,
    required String voice,
    required double rate,
    required String filePath,
    required int bytes,
    required int createdAt,
    required int lastUsedAt,
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       engine = Value(engine),
       voice = Value(voice),
       rate = Value(rate),
       filePath = Value(filePath),
       bytes = Value(bytes),
       createdAt = Value(createdAt),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<TtsCache> custom({
    Expression<String>? hash,
    Expression<String>? engine,
    Expression<String>? voice,
    Expression<double>? rate,
    Expression<String>? filePath,
    Expression<int>? bytes,
    Expression<int>? createdAt,
    Expression<int>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (hash != null) 'hash': hash,
      if (engine != null) 'engine': engine,
      if (voice != null) 'voice': voice,
      if (rate != null) 'rate': rate,
      if (filePath != null) 'file_path': filePath,
      if (bytes != null) 'bytes': bytes,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TtsCachesCompanion copyWith({
    Value<String>? hash,
    Value<String>? engine,
    Value<String>? voice,
    Value<double>? rate,
    Value<String>? filePath,
    Value<int>? bytes,
    Value<int>? createdAt,
    Value<int>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return TtsCachesCompanion(
      hash: hash ?? this.hash,
      engine: engine ?? this.engine,
      voice: voice ?? this.voice,
      rate: rate ?? this.rate,
      filePath: filePath ?? this.filePath,
      bytes: bytes ?? this.bytes,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (engine.present) {
      map['engine'] = Variable<String>(engine.value);
    }
    if (voice.present) {
      map['voice'] = Variable<String>(voice.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<int>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TtsCachesCompanion(')
          ..write('hash: $hash, ')
          ..write('engine: $engine, ')
          ..write('voice: $voice, ')
          ..write('rate: $rate, ')
          ..write('filePath: $filePath, ')
          ..write('bytes: $bytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppMetasTable extends AppMetas with TableInfo<$AppMetasTable, AppMeta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMeta> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMeta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMeta(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppMetasTable createAlias(String alias) {
    return $AppMetasTable(attachedDatabase, alias);
  }
}

class AppMeta extends DataClass implements Insertable<AppMeta> {
  final String key;
  final String value;
  const AppMeta({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetasCompanion toCompanion(bool nullToAbsent) {
    return AppMetasCompanion(key: Value(key), value: Value(value));
  }

  factory AppMeta.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMeta(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppMeta copyWith({String? key, String? value}) =>
      AppMeta(key: key ?? this.key, value: value ?? this.value);
  AppMeta copyWithCompanion(AppMetasCompanion data) {
    return AppMeta(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMeta(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMeta && other.key == this.key && other.value == this.value);
}

class AppMetasCompanion extends UpdateCompanion<AppMeta> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetasCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetasCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMeta> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetasCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetasCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetasCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MaterialsTable extends Materials
    with TableInfo<$MaterialsTable, Material> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaterialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaPathMeta = const VerificationMeta(
    'mediaPath',
  );
  @override
  late final GeneratedColumn<String> mediaPath = GeneratedColumn<String>(
    'media_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaNameMeta = const VerificationMeta(
    'mediaName',
  );
  @override
  late final GeneratedColumn<String> mediaName = GeneratedColumn<String>(
    'media_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaKindMeta = const VerificationMeta(
    'mediaKind',
  );
  @override
  late final GeneratedColumn<String> mediaKind = GeneratedColumn<String>(
    'media_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleNameMeta = const VerificationMeta(
    'subtitleName',
  );
  @override
  late final GeneratedColumn<String> subtitleName = GeneratedColumn<String>(
    'subtitle_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceHashMeta = const VerificationMeta(
    'sourceHash',
  );
  @override
  late final GeneratedColumn<String> sourceHash = GeneratedColumn<String>(
    'source_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _segmentCountMeta = const VerificationMeta(
    'segmentCount',
  );
  @override
  late final GeneratedColumn<int> segmentCount = GeneratedColumn<int>(
    'segment_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPracticedAtMeta = const VerificationMeta(
    'lastPracticedAt',
  );
  @override
  late final GeneratedColumn<int> lastPracticedAt = GeneratedColumn<int>(
    'last_practiced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    mediaPath,
    mediaName,
    mediaKind,
    subtitleName,
    sourceHash,
    durationMs,
    segmentCount,
    createdAt,
    lastPracticedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'material';
  @override
  VerificationContext validateIntegrity(
    Insertable<Material> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('media_path')) {
      context.handle(
        _mediaPathMeta,
        mediaPath.isAcceptableOrUnknown(data['media_path']!, _mediaPathMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaPathMeta);
    }
    if (data.containsKey('media_name')) {
      context.handle(
        _mediaNameMeta,
        mediaName.isAcceptableOrUnknown(data['media_name']!, _mediaNameMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaNameMeta);
    }
    if (data.containsKey('media_kind')) {
      context.handle(
        _mediaKindMeta,
        mediaKind.isAcceptableOrUnknown(data['media_kind']!, _mediaKindMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaKindMeta);
    }
    if (data.containsKey('subtitle_name')) {
      context.handle(
        _subtitleNameMeta,
        subtitleName.isAcceptableOrUnknown(
          data['subtitle_name']!,
          _subtitleNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subtitleNameMeta);
    }
    if (data.containsKey('source_hash')) {
      context.handle(
        _sourceHashMeta,
        sourceHash.isAcceptableOrUnknown(data['source_hash']!, _sourceHashMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceHashMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('segment_count')) {
      context.handle(
        _segmentCountMeta,
        segmentCount.isAcceptableOrUnknown(
          data['segment_count']!,
          _segmentCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_segmentCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_practiced_at')) {
      context.handle(
        _lastPracticedAtMeta,
        lastPracticedAt.isAcceptableOrUnknown(
          data['last_practiced_at']!,
          _lastPracticedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Material map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Material(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      mediaPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_path'],
      )!,
      mediaName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_name'],
      )!,
      mediaKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_kind'],
      )!,
      subtitleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle_name'],
      )!,
      sourceHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_hash'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      segmentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segment_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      lastPracticedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_practiced_at'],
      ),
    );
  }

  @override
  $MaterialsTable createAlias(String alias) {
    return $MaterialsTable(attachedDatabase, alias);
  }
}

class Material extends DataClass implements Insertable<Material> {
  final String id;
  final String title;
  final String mediaPath;
  final String mediaName;
  final String mediaKind;
  final String subtitleName;
  final String sourceHash;
  final int durationMs;
  final int segmentCount;
  final int createdAt;
  final int? lastPracticedAt;
  const Material({
    required this.id,
    required this.title,
    required this.mediaPath,
    required this.mediaName,
    required this.mediaKind,
    required this.subtitleName,
    required this.sourceHash,
    required this.durationMs,
    required this.segmentCount,
    required this.createdAt,
    this.lastPracticedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['media_path'] = Variable<String>(mediaPath);
    map['media_name'] = Variable<String>(mediaName);
    map['media_kind'] = Variable<String>(mediaKind);
    map['subtitle_name'] = Variable<String>(subtitleName);
    map['source_hash'] = Variable<String>(sourceHash);
    map['duration_ms'] = Variable<int>(durationMs);
    map['segment_count'] = Variable<int>(segmentCount);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastPracticedAt != null) {
      map['last_practiced_at'] = Variable<int>(lastPracticedAt);
    }
    return map;
  }

  MaterialsCompanion toCompanion(bool nullToAbsent) {
    return MaterialsCompanion(
      id: Value(id),
      title: Value(title),
      mediaPath: Value(mediaPath),
      mediaName: Value(mediaName),
      mediaKind: Value(mediaKind),
      subtitleName: Value(subtitleName),
      sourceHash: Value(sourceHash),
      durationMs: Value(durationMs),
      segmentCount: Value(segmentCount),
      createdAt: Value(createdAt),
      lastPracticedAt: lastPracticedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPracticedAt),
    );
  }

  factory Material.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Material(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      mediaPath: serializer.fromJson<String>(json['mediaPath']),
      mediaName: serializer.fromJson<String>(json['mediaName']),
      mediaKind: serializer.fromJson<String>(json['mediaKind']),
      subtitleName: serializer.fromJson<String>(json['subtitleName']),
      sourceHash: serializer.fromJson<String>(json['sourceHash']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      segmentCount: serializer.fromJson<int>(json['segmentCount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastPracticedAt: serializer.fromJson<int?>(json['lastPracticedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'mediaPath': serializer.toJson<String>(mediaPath),
      'mediaName': serializer.toJson<String>(mediaName),
      'mediaKind': serializer.toJson<String>(mediaKind),
      'subtitleName': serializer.toJson<String>(subtitleName),
      'sourceHash': serializer.toJson<String>(sourceHash),
      'durationMs': serializer.toJson<int>(durationMs),
      'segmentCount': serializer.toJson<int>(segmentCount),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastPracticedAt': serializer.toJson<int?>(lastPracticedAt),
    };
  }

  Material copyWith({
    String? id,
    String? title,
    String? mediaPath,
    String? mediaName,
    String? mediaKind,
    String? subtitleName,
    String? sourceHash,
    int? durationMs,
    int? segmentCount,
    int? createdAt,
    Value<int?> lastPracticedAt = const Value.absent(),
  }) => Material(
    id: id ?? this.id,
    title: title ?? this.title,
    mediaPath: mediaPath ?? this.mediaPath,
    mediaName: mediaName ?? this.mediaName,
    mediaKind: mediaKind ?? this.mediaKind,
    subtitleName: subtitleName ?? this.subtitleName,
    sourceHash: sourceHash ?? this.sourceHash,
    durationMs: durationMs ?? this.durationMs,
    segmentCount: segmentCount ?? this.segmentCount,
    createdAt: createdAt ?? this.createdAt,
    lastPracticedAt: lastPracticedAt.present
        ? lastPracticedAt.value
        : this.lastPracticedAt,
  );
  Material copyWithCompanion(MaterialsCompanion data) {
    return Material(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      mediaPath: data.mediaPath.present ? data.mediaPath.value : this.mediaPath,
      mediaName: data.mediaName.present ? data.mediaName.value : this.mediaName,
      mediaKind: data.mediaKind.present ? data.mediaKind.value : this.mediaKind,
      subtitleName: data.subtitleName.present
          ? data.subtitleName.value
          : this.subtitleName,
      sourceHash: data.sourceHash.present
          ? data.sourceHash.value
          : this.sourceHash,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      segmentCount: data.segmentCount.present
          ? data.segmentCount.value
          : this.segmentCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastPracticedAt: data.lastPracticedAt.present
          ? data.lastPracticedAt.value
          : this.lastPracticedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Material(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('mediaName: $mediaName, ')
          ..write('mediaKind: $mediaKind, ')
          ..write('subtitleName: $subtitleName, ')
          ..write('sourceHash: $sourceHash, ')
          ..write('durationMs: $durationMs, ')
          ..write('segmentCount: $segmentCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastPracticedAt: $lastPracticedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    mediaPath,
    mediaName,
    mediaKind,
    subtitleName,
    sourceHash,
    durationMs,
    segmentCount,
    createdAt,
    lastPracticedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Material &&
          other.id == this.id &&
          other.title == this.title &&
          other.mediaPath == this.mediaPath &&
          other.mediaName == this.mediaName &&
          other.mediaKind == this.mediaKind &&
          other.subtitleName == this.subtitleName &&
          other.sourceHash == this.sourceHash &&
          other.durationMs == this.durationMs &&
          other.segmentCount == this.segmentCount &&
          other.createdAt == this.createdAt &&
          other.lastPracticedAt == this.lastPracticedAt);
}

class MaterialsCompanion extends UpdateCompanion<Material> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> mediaPath;
  final Value<String> mediaName;
  final Value<String> mediaKind;
  final Value<String> subtitleName;
  final Value<String> sourceHash;
  final Value<int> durationMs;
  final Value<int> segmentCount;
  final Value<int> createdAt;
  final Value<int?> lastPracticedAt;
  final Value<int> rowid;
  const MaterialsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.mediaName = const Value.absent(),
    this.mediaKind = const Value.absent(),
    this.subtitleName = const Value.absent(),
    this.sourceHash = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.segmentCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastPracticedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MaterialsCompanion.insert({
    required String id,
    required String title,
    required String mediaPath,
    required String mediaName,
    required String mediaKind,
    required String subtitleName,
    required String sourceHash,
    required int durationMs,
    required int segmentCount,
    required int createdAt,
    this.lastPracticedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       mediaPath = Value(mediaPath),
       mediaName = Value(mediaName),
       mediaKind = Value(mediaKind),
       subtitleName = Value(subtitleName),
       sourceHash = Value(sourceHash),
       durationMs = Value(durationMs),
       segmentCount = Value(segmentCount),
       createdAt = Value(createdAt);
  static Insertable<Material> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? mediaPath,
    Expression<String>? mediaName,
    Expression<String>? mediaKind,
    Expression<String>? subtitleName,
    Expression<String>? sourceHash,
    Expression<int>? durationMs,
    Expression<int>? segmentCount,
    Expression<int>? createdAt,
    Expression<int>? lastPracticedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (mediaPath != null) 'media_path': mediaPath,
      if (mediaName != null) 'media_name': mediaName,
      if (mediaKind != null) 'media_kind': mediaKind,
      if (subtitleName != null) 'subtitle_name': subtitleName,
      if (sourceHash != null) 'source_hash': sourceHash,
      if (durationMs != null) 'duration_ms': durationMs,
      if (segmentCount != null) 'segment_count': segmentCount,
      if (createdAt != null) 'created_at': createdAt,
      if (lastPracticedAt != null) 'last_practiced_at': lastPracticedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MaterialsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? mediaPath,
    Value<String>? mediaName,
    Value<String>? mediaKind,
    Value<String>? subtitleName,
    Value<String>? sourceHash,
    Value<int>? durationMs,
    Value<int>? segmentCount,
    Value<int>? createdAt,
    Value<int?>? lastPracticedAt,
    Value<int>? rowid,
  }) {
    return MaterialsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      mediaPath: mediaPath ?? this.mediaPath,
      mediaName: mediaName ?? this.mediaName,
      mediaKind: mediaKind ?? this.mediaKind,
      subtitleName: subtitleName ?? this.subtitleName,
      sourceHash: sourceHash ?? this.sourceHash,
      durationMs: durationMs ?? this.durationMs,
      segmentCount: segmentCount ?? this.segmentCount,
      createdAt: createdAt ?? this.createdAt,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (mediaPath.present) {
      map['media_path'] = Variable<String>(mediaPath.value);
    }
    if (mediaName.present) {
      map['media_name'] = Variable<String>(mediaName.value);
    }
    if (mediaKind.present) {
      map['media_kind'] = Variable<String>(mediaKind.value);
    }
    if (subtitleName.present) {
      map['subtitle_name'] = Variable<String>(subtitleName.value);
    }
    if (sourceHash.present) {
      map['source_hash'] = Variable<String>(sourceHash.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (segmentCount.present) {
      map['segment_count'] = Variable<int>(segmentCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastPracticedAt.present) {
      map['last_practiced_at'] = Variable<int>(lastPracticedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaterialsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('mediaName: $mediaName, ')
          ..write('mediaKind: $mediaKind, ')
          ..write('subtitleName: $subtitleName, ')
          ..write('sourceHash: $sourceHash, ')
          ..write('durationMs: $durationMs, ')
          ..write('segmentCount: $segmentCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastPracticedAt: $lastPracticedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MaterialSegmentsTable extends MaterialSegments
    with TableInfo<$MaterialSegmentsTable, MaterialSegment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaterialSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _materialIdMeta = const VerificationMeta(
    'materialId',
  );
  @override
  late final GeneratedColumn<String> materialId = GeneratedColumn<String>(
    'material_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textEnMeta = const VerificationMeta('textEn');
  @override
  late final GeneratedColumn<String> textEn = GeneratedColumn<String>(
    'text_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMsMeta = const VerificationMeta(
    'startMs',
  );
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
    'word_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isHardMeta = const VerificationMeta('isHard');
  @override
  late final GeneratedColumn<int> isHard = GeneratedColumn<int>(
    'is_hard',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    materialId,
    seq,
    textEn,
    startMs,
    endMs,
    wordCount,
    isHard,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'material_segment';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaterialSegment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('material_id')) {
      context.handle(
        _materialIdMeta,
        materialId.isAcceptableOrUnknown(data['material_id']!, _materialIdMeta),
      );
    } else if (isInserting) {
      context.missing(_materialIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('text_en')) {
      context.handle(
        _textEnMeta,
        textEn.isAcceptableOrUnknown(data['text_en']!, _textEnMeta),
      );
    } else if (isInserting) {
      context.missing(_textEnMeta);
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    } else if (isInserting) {
      context.missing(_endMsMeta);
    }
    if (data.containsKey('word_count')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta),
      );
    } else if (isInserting) {
      context.missing(_wordCountMeta);
    }
    if (data.containsKey('is_hard')) {
      context.handle(
        _isHardMeta,
        isHard.isAcceptableOrUnknown(data['is_hard']!, _isHardMeta),
      );
    } else if (isInserting) {
      context.missing(_isHardMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaterialSegment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaterialSegment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      materialId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}material_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      textEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_en'],
      )!,
      startMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      )!,
      endMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      )!,
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_count'],
      )!,
      isHard: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_hard'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MaterialSegmentsTable createAlias(String alias) {
    return $MaterialSegmentsTable(attachedDatabase, alias);
  }
}

class MaterialSegment extends DataClass implements Insertable<MaterialSegment> {
  final String id;
  final String materialId;
  final int seq;
  final String textEn;
  final int startMs;
  final int endMs;
  final int wordCount;
  final int isHard;
  final int createdAt;
  const MaterialSegment({
    required this.id,
    required this.materialId,
    required this.seq,
    required this.textEn,
    required this.startMs,
    required this.endMs,
    required this.wordCount,
    required this.isHard,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['material_id'] = Variable<String>(materialId);
    map['seq'] = Variable<int>(seq);
    map['text_en'] = Variable<String>(textEn);
    map['start_ms'] = Variable<int>(startMs);
    map['end_ms'] = Variable<int>(endMs);
    map['word_count'] = Variable<int>(wordCount);
    map['is_hard'] = Variable<int>(isHard);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  MaterialSegmentsCompanion toCompanion(bool nullToAbsent) {
    return MaterialSegmentsCompanion(
      id: Value(id),
      materialId: Value(materialId),
      seq: Value(seq),
      textEn: Value(textEn),
      startMs: Value(startMs),
      endMs: Value(endMs),
      wordCount: Value(wordCount),
      isHard: Value(isHard),
      createdAt: Value(createdAt),
    );
  }

  factory MaterialSegment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaterialSegment(
      id: serializer.fromJson<String>(json['id']),
      materialId: serializer.fromJson<String>(json['materialId']),
      seq: serializer.fromJson<int>(json['seq']),
      textEn: serializer.fromJson<String>(json['textEn']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int>(json['endMs']),
      wordCount: serializer.fromJson<int>(json['wordCount']),
      isHard: serializer.fromJson<int>(json['isHard']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'materialId': serializer.toJson<String>(materialId),
      'seq': serializer.toJson<int>(seq),
      'textEn': serializer.toJson<String>(textEn),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int>(endMs),
      'wordCount': serializer.toJson<int>(wordCount),
      'isHard': serializer.toJson<int>(isHard),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  MaterialSegment copyWith({
    String? id,
    String? materialId,
    int? seq,
    String? textEn,
    int? startMs,
    int? endMs,
    int? wordCount,
    int? isHard,
    int? createdAt,
  }) => MaterialSegment(
    id: id ?? this.id,
    materialId: materialId ?? this.materialId,
    seq: seq ?? this.seq,
    textEn: textEn ?? this.textEn,
    startMs: startMs ?? this.startMs,
    endMs: endMs ?? this.endMs,
    wordCount: wordCount ?? this.wordCount,
    isHard: isHard ?? this.isHard,
    createdAt: createdAt ?? this.createdAt,
  );
  MaterialSegment copyWithCompanion(MaterialSegmentsCompanion data) {
    return MaterialSegment(
      id: data.id.present ? data.id.value : this.id,
      materialId: data.materialId.present
          ? data.materialId.value
          : this.materialId,
      seq: data.seq.present ? data.seq.value : this.seq,
      textEn: data.textEn.present ? data.textEn.value : this.textEn,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      isHard: data.isHard.present ? data.isHard.value : this.isHard,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaterialSegment(')
          ..write('id: $id, ')
          ..write('materialId: $materialId, ')
          ..write('seq: $seq, ')
          ..write('textEn: $textEn, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('wordCount: $wordCount, ')
          ..write('isHard: $isHard, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    materialId,
    seq,
    textEn,
    startMs,
    endMs,
    wordCount,
    isHard,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterialSegment &&
          other.id == this.id &&
          other.materialId == this.materialId &&
          other.seq == this.seq &&
          other.textEn == this.textEn &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs &&
          other.wordCount == this.wordCount &&
          other.isHard == this.isHard &&
          other.createdAt == this.createdAt);
}

class MaterialSegmentsCompanion extends UpdateCompanion<MaterialSegment> {
  final Value<String> id;
  final Value<String> materialId;
  final Value<int> seq;
  final Value<String> textEn;
  final Value<int> startMs;
  final Value<int> endMs;
  final Value<int> wordCount;
  final Value<int> isHard;
  final Value<int> createdAt;
  final Value<int> rowid;
  const MaterialSegmentsCompanion({
    this.id = const Value.absent(),
    this.materialId = const Value.absent(),
    this.seq = const Value.absent(),
    this.textEn = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.isHard = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MaterialSegmentsCompanion.insert({
    required String id,
    required String materialId,
    required int seq,
    required String textEn,
    required int startMs,
    required int endMs,
    required int wordCount,
    required int isHard,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       materialId = Value(materialId),
       seq = Value(seq),
       textEn = Value(textEn),
       startMs = Value(startMs),
       endMs = Value(endMs),
       wordCount = Value(wordCount),
       isHard = Value(isHard),
       createdAt = Value(createdAt);
  static Insertable<MaterialSegment> custom({
    Expression<String>? id,
    Expression<String>? materialId,
    Expression<int>? seq,
    Expression<String>? textEn,
    Expression<int>? startMs,
    Expression<int>? endMs,
    Expression<int>? wordCount,
    Expression<int>? isHard,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (materialId != null) 'material_id': materialId,
      if (seq != null) 'seq': seq,
      if (textEn != null) 'text_en': textEn,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
      if (wordCount != null) 'word_count': wordCount,
      if (isHard != null) 'is_hard': isHard,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MaterialSegmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? materialId,
    Value<int>? seq,
    Value<String>? textEn,
    Value<int>? startMs,
    Value<int>? endMs,
    Value<int>? wordCount,
    Value<int>? isHard,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return MaterialSegmentsCompanion(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      seq: seq ?? this.seq,
      textEn: textEn ?? this.textEn,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      wordCount: wordCount ?? this.wordCount,
      isHard: isHard ?? this.isHard,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (materialId.present) {
      map['material_id'] = Variable<String>(materialId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (textEn.present) {
      map['text_en'] = Variable<String>(textEn.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (isHard.present) {
      map['is_hard'] = Variable<int>(isHard.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaterialSegmentsCompanion(')
          ..write('id: $id, ')
          ..write('materialId: $materialId, ')
          ..write('seq: $seq, ')
          ..write('textEn: $textEn, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('wordCount: $wordCount, ')
          ..write('isHard: $isHard, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DictationAttemptsTable extends DictationAttempts
    with TableInfo<$DictationAttemptsTable, DictationAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictationAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _materialIdMeta = const VerificationMeta(
    'materialId',
  );
  @override
  late final GeneratedColumn<String> materialId = GeneratedColumn<String>(
    'material_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _segmentIdMeta = const VerificationMeta(
    'segmentId',
  );
  @override
  late final GeneratedColumn<String> segmentId = GeneratedColumn<String>(
    'segment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userTextMeta = const VerificationMeta(
    'userText',
  );
  @override
  late final GeneratedColumn<String> userText = GeneratedColumn<String>(
    'user_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passedMeta = const VerificationMeta('passed');
  @override
  late final GeneratedColumn<int> passed = GeneratedColumn<int>(
    'passed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diffJsonMeta = const VerificationMeta(
    'diffJson',
  );
  @override
  late final GeneratedColumn<String> diffJson = GeneratedColumn<String>(
    'diff_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    materialId,
    segmentId,
    userText,
    accuracy,
    passed,
    diffJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictation_attempt';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictationAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('material_id')) {
      context.handle(
        _materialIdMeta,
        materialId.isAcceptableOrUnknown(data['material_id']!, _materialIdMeta),
      );
    } else if (isInserting) {
      context.missing(_materialIdMeta);
    }
    if (data.containsKey('segment_id')) {
      context.handle(
        _segmentIdMeta,
        segmentId.isAcceptableOrUnknown(data['segment_id']!, _segmentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_segmentIdMeta);
    }
    if (data.containsKey('user_text')) {
      context.handle(
        _userTextMeta,
        userText.isAcceptableOrUnknown(data['user_text']!, _userTextMeta),
      );
    } else if (isInserting) {
      context.missing(_userTextMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    } else if (isInserting) {
      context.missing(_accuracyMeta);
    }
    if (data.containsKey('passed')) {
      context.handle(
        _passedMeta,
        passed.isAcceptableOrUnknown(data['passed']!, _passedMeta),
      );
    } else if (isInserting) {
      context.missing(_passedMeta);
    }
    if (data.containsKey('diff_json')) {
      context.handle(
        _diffJsonMeta,
        diffJson.isAcceptableOrUnknown(data['diff_json']!, _diffJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_diffJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DictationAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictationAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      materialId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}material_id'],
      )!,
      segmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment_id'],
      )!,
      userText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_text'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      )!,
      passed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}passed'],
      )!,
      diffJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diff_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DictationAttemptsTable createAlias(String alias) {
    return $DictationAttemptsTable(attachedDatabase, alias);
  }
}

class DictationAttempt extends DataClass
    implements Insertable<DictationAttempt> {
  final String id;
  final String materialId;
  final String segmentId;
  final String userText;
  final double accuracy;
  final int passed;
  final String diffJson;
  final int createdAt;
  const DictationAttempt({
    required this.id,
    required this.materialId,
    required this.segmentId,
    required this.userText,
    required this.accuracy,
    required this.passed,
    required this.diffJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['material_id'] = Variable<String>(materialId);
    map['segment_id'] = Variable<String>(segmentId);
    map['user_text'] = Variable<String>(userText);
    map['accuracy'] = Variable<double>(accuracy);
    map['passed'] = Variable<int>(passed);
    map['diff_json'] = Variable<String>(diffJson);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  DictationAttemptsCompanion toCompanion(bool nullToAbsent) {
    return DictationAttemptsCompanion(
      id: Value(id),
      materialId: Value(materialId),
      segmentId: Value(segmentId),
      userText: Value(userText),
      accuracy: Value(accuracy),
      passed: Value(passed),
      diffJson: Value(diffJson),
      createdAt: Value(createdAt),
    );
  }

  factory DictationAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictationAttempt(
      id: serializer.fromJson<String>(json['id']),
      materialId: serializer.fromJson<String>(json['materialId']),
      segmentId: serializer.fromJson<String>(json['segmentId']),
      userText: serializer.fromJson<String>(json['userText']),
      accuracy: serializer.fromJson<double>(json['accuracy']),
      passed: serializer.fromJson<int>(json['passed']),
      diffJson: serializer.fromJson<String>(json['diffJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'materialId': serializer.toJson<String>(materialId),
      'segmentId': serializer.toJson<String>(segmentId),
      'userText': serializer.toJson<String>(userText),
      'accuracy': serializer.toJson<double>(accuracy),
      'passed': serializer.toJson<int>(passed),
      'diffJson': serializer.toJson<String>(diffJson),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  DictationAttempt copyWith({
    String? id,
    String? materialId,
    String? segmentId,
    String? userText,
    double? accuracy,
    int? passed,
    String? diffJson,
    int? createdAt,
  }) => DictationAttempt(
    id: id ?? this.id,
    materialId: materialId ?? this.materialId,
    segmentId: segmentId ?? this.segmentId,
    userText: userText ?? this.userText,
    accuracy: accuracy ?? this.accuracy,
    passed: passed ?? this.passed,
    diffJson: diffJson ?? this.diffJson,
    createdAt: createdAt ?? this.createdAt,
  );
  DictationAttempt copyWithCompanion(DictationAttemptsCompanion data) {
    return DictationAttempt(
      id: data.id.present ? data.id.value : this.id,
      materialId: data.materialId.present
          ? data.materialId.value
          : this.materialId,
      segmentId: data.segmentId.present ? data.segmentId.value : this.segmentId,
      userText: data.userText.present ? data.userText.value : this.userText,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      passed: data.passed.present ? data.passed.value : this.passed,
      diffJson: data.diffJson.present ? data.diffJson.value : this.diffJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictationAttempt(')
          ..write('id: $id, ')
          ..write('materialId: $materialId, ')
          ..write('segmentId: $segmentId, ')
          ..write('userText: $userText, ')
          ..write('accuracy: $accuracy, ')
          ..write('passed: $passed, ')
          ..write('diffJson: $diffJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    materialId,
    segmentId,
    userText,
    accuracy,
    passed,
    diffJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictationAttempt &&
          other.id == this.id &&
          other.materialId == this.materialId &&
          other.segmentId == this.segmentId &&
          other.userText == this.userText &&
          other.accuracy == this.accuracy &&
          other.passed == this.passed &&
          other.diffJson == this.diffJson &&
          other.createdAt == this.createdAt);
}

class DictationAttemptsCompanion extends UpdateCompanion<DictationAttempt> {
  final Value<String> id;
  final Value<String> materialId;
  final Value<String> segmentId;
  final Value<String> userText;
  final Value<double> accuracy;
  final Value<int> passed;
  final Value<String> diffJson;
  final Value<int> createdAt;
  final Value<int> rowid;
  const DictationAttemptsCompanion({
    this.id = const Value.absent(),
    this.materialId = const Value.absent(),
    this.segmentId = const Value.absent(),
    this.userText = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.passed = const Value.absent(),
    this.diffJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DictationAttemptsCompanion.insert({
    required String id,
    required String materialId,
    required String segmentId,
    required String userText,
    required double accuracy,
    required int passed,
    required String diffJson,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       materialId = Value(materialId),
       segmentId = Value(segmentId),
       userText = Value(userText),
       accuracy = Value(accuracy),
       passed = Value(passed),
       diffJson = Value(diffJson),
       createdAt = Value(createdAt);
  static Insertable<DictationAttempt> custom({
    Expression<String>? id,
    Expression<String>? materialId,
    Expression<String>? segmentId,
    Expression<String>? userText,
    Expression<double>? accuracy,
    Expression<int>? passed,
    Expression<String>? diffJson,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (materialId != null) 'material_id': materialId,
      if (segmentId != null) 'segment_id': segmentId,
      if (userText != null) 'user_text': userText,
      if (accuracy != null) 'accuracy': accuracy,
      if (passed != null) 'passed': passed,
      if (diffJson != null) 'diff_json': diffJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DictationAttemptsCompanion copyWith({
    Value<String>? id,
    Value<String>? materialId,
    Value<String>? segmentId,
    Value<String>? userText,
    Value<double>? accuracy,
    Value<int>? passed,
    Value<String>? diffJson,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return DictationAttemptsCompanion(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      segmentId: segmentId ?? this.segmentId,
      userText: userText ?? this.userText,
      accuracy: accuracy ?? this.accuracy,
      passed: passed ?? this.passed,
      diffJson: diffJson ?? this.diffJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (materialId.present) {
      map['material_id'] = Variable<String>(materialId.value);
    }
    if (segmentId.present) {
      map['segment_id'] = Variable<String>(segmentId.value);
    }
    if (userText.present) {
      map['user_text'] = Variable<String>(userText.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (passed.present) {
      map['passed'] = Variable<int>(passed.value);
    }
    if (diffJson.present) {
      map['diff_json'] = Variable<String>(diffJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictationAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('materialId: $materialId, ')
          ..write('segmentId: $segmentId, ')
          ..write('userText: $userText, ')
          ..write('accuracy: $accuracy, ')
          ..write('passed: $passed, ')
          ..write('diffJson: $diffJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewItemRowsTable extends ReviewItemRows
    with TableInfo<$ReviewItemRowsTable, ReviewItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewItemRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textEnMeta = const VerificationMeta('textEn');
  @override
  late final GeneratedColumn<String> textEn = GeneratedColumn<String>(
    'text_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textZhMeta = const VerificationMeta('textZh');
  @override
  late final GeneratedColumn<String> textZh = GeneratedColumn<String>(
    'text_zh',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<int> dueAt = GeneratedColumn<int>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<int> stage = GeneratedColumn<int>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _streakMeta = const VerificationMeta('streak');
  @override
  late final GeneratedColumn<int> streak = GeneratedColumn<int>(
    'streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consolidatedMeta = const VerificationMeta(
    'consolidated',
  );
  @override
  late final GeneratedColumn<int> consolidated = GeneratedColumn<int>(
    'consolidated',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPassedMeta = const VerificationMeta(
    'lastPassed',
  );
  @override
  late final GeneratedColumn<int> lastPassed = GeneratedColumn<int>(
    'last_passed',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceType,
    sourceId,
    textEn,
    textZh,
    dueAt,
    stage,
    streak,
    consolidated,
    lastPassed,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_item';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('text_en')) {
      context.handle(
        _textEnMeta,
        textEn.isAcceptableOrUnknown(data['text_en']!, _textEnMeta),
      );
    } else if (isInserting) {
      context.missing(_textEnMeta);
    }
    if (data.containsKey('text_zh')) {
      context.handle(
        _textZhMeta,
        textZh.isAcceptableOrUnknown(data['text_zh']!, _textZhMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    if (data.containsKey('streak')) {
      context.handle(
        _streakMeta,
        streak.isAcceptableOrUnknown(data['streak']!, _streakMeta),
      );
    } else if (isInserting) {
      context.missing(_streakMeta);
    }
    if (data.containsKey('consolidated')) {
      context.handle(
        _consolidatedMeta,
        consolidated.isAcceptableOrUnknown(
          data['consolidated']!,
          _consolidatedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consolidatedMeta);
    }
    if (data.containsKey('last_passed')) {
      context.handle(
        _lastPassedMeta,
        lastPassed.isAcceptableOrUnknown(data['last_passed']!, _lastPassedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      textEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_en'],
      )!,
      textZh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_zh'],
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage'],
      )!,
      streak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak'],
      )!,
      consolidated: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consolidated'],
      )!,
      lastPassed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_passed'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReviewItemRowsTable createAlias(String alias) {
    return $ReviewItemRowsTable(attachedDatabase, alias);
  }
}

class ReviewItemRow extends DataClass implements Insertable<ReviewItemRow> {
  final String id;
  final String sourceType;
  final String sourceId;
  final String textEn;
  final String? textZh;
  final int dueAt;
  final int stage;
  final int streak;
  final int consolidated;
  final int? lastPassed;
  final int createdAt;
  const ReviewItemRow({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.textEn,
    this.textZh,
    required this.dueAt,
    required this.stage,
    required this.streak,
    required this.consolidated,
    this.lastPassed,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_type'] = Variable<String>(sourceType);
    map['source_id'] = Variable<String>(sourceId);
    map['text_en'] = Variable<String>(textEn);
    if (!nullToAbsent || textZh != null) {
      map['text_zh'] = Variable<String>(textZh);
    }
    map['due_at'] = Variable<int>(dueAt);
    map['stage'] = Variable<int>(stage);
    map['streak'] = Variable<int>(streak);
    map['consolidated'] = Variable<int>(consolidated);
    if (!nullToAbsent || lastPassed != null) {
      map['last_passed'] = Variable<int>(lastPassed);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ReviewItemRowsCompanion toCompanion(bool nullToAbsent) {
    return ReviewItemRowsCompanion(
      id: Value(id),
      sourceType: Value(sourceType),
      sourceId: Value(sourceId),
      textEn: Value(textEn),
      textZh: textZh == null && nullToAbsent
          ? const Value.absent()
          : Value(textZh),
      dueAt: Value(dueAt),
      stage: Value(stage),
      streak: Value(streak),
      consolidated: Value(consolidated),
      lastPassed: lastPassed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPassed),
      createdAt: Value(createdAt),
    );
  }

  factory ReviewItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewItemRow(
      id: serializer.fromJson<String>(json['id']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      textEn: serializer.fromJson<String>(json['textEn']),
      textZh: serializer.fromJson<String?>(json['textZh']),
      dueAt: serializer.fromJson<int>(json['dueAt']),
      stage: serializer.fromJson<int>(json['stage']),
      streak: serializer.fromJson<int>(json['streak']),
      consolidated: serializer.fromJson<int>(json['consolidated']),
      lastPassed: serializer.fromJson<int?>(json['lastPassed']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceId': serializer.toJson<String>(sourceId),
      'textEn': serializer.toJson<String>(textEn),
      'textZh': serializer.toJson<String?>(textZh),
      'dueAt': serializer.toJson<int>(dueAt),
      'stage': serializer.toJson<int>(stage),
      'streak': serializer.toJson<int>(streak),
      'consolidated': serializer.toJson<int>(consolidated),
      'lastPassed': serializer.toJson<int?>(lastPassed),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ReviewItemRow copyWith({
    String? id,
    String? sourceType,
    String? sourceId,
    String? textEn,
    Value<String?> textZh = const Value.absent(),
    int? dueAt,
    int? stage,
    int? streak,
    int? consolidated,
    Value<int?> lastPassed = const Value.absent(),
    int? createdAt,
  }) => ReviewItemRow(
    id: id ?? this.id,
    sourceType: sourceType ?? this.sourceType,
    sourceId: sourceId ?? this.sourceId,
    textEn: textEn ?? this.textEn,
    textZh: textZh.present ? textZh.value : this.textZh,
    dueAt: dueAt ?? this.dueAt,
    stage: stage ?? this.stage,
    streak: streak ?? this.streak,
    consolidated: consolidated ?? this.consolidated,
    lastPassed: lastPassed.present ? lastPassed.value : this.lastPassed,
    createdAt: createdAt ?? this.createdAt,
  );
  ReviewItemRow copyWithCompanion(ReviewItemRowsCompanion data) {
    return ReviewItemRow(
      id: data.id.present ? data.id.value : this.id,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      textEn: data.textEn.present ? data.textEn.value : this.textEn,
      textZh: data.textZh.present ? data.textZh.value : this.textZh,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      stage: data.stage.present ? data.stage.value : this.stage,
      streak: data.streak.present ? data.streak.value : this.streak,
      consolidated: data.consolidated.present
          ? data.consolidated.value
          : this.consolidated,
      lastPassed: data.lastPassed.present
          ? data.lastPassed.value
          : this.lastPassed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewItemRow(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('textEn: $textEn, ')
          ..write('textZh: $textZh, ')
          ..write('dueAt: $dueAt, ')
          ..write('stage: $stage, ')
          ..write('streak: $streak, ')
          ..write('consolidated: $consolidated, ')
          ..write('lastPassed: $lastPassed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceType,
    sourceId,
    textEn,
    textZh,
    dueAt,
    stage,
    streak,
    consolidated,
    lastPassed,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewItemRow &&
          other.id == this.id &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.textEn == this.textEn &&
          other.textZh == this.textZh &&
          other.dueAt == this.dueAt &&
          other.stage == this.stage &&
          other.streak == this.streak &&
          other.consolidated == this.consolidated &&
          other.lastPassed == this.lastPassed &&
          other.createdAt == this.createdAt);
}

class ReviewItemRowsCompanion extends UpdateCompanion<ReviewItemRow> {
  final Value<String> id;
  final Value<String> sourceType;
  final Value<String> sourceId;
  final Value<String> textEn;
  final Value<String?> textZh;
  final Value<int> dueAt;
  final Value<int> stage;
  final Value<int> streak;
  final Value<int> consolidated;
  final Value<int?> lastPassed;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ReviewItemRowsCompanion({
    this.id = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.textEn = const Value.absent(),
    this.textZh = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.stage = const Value.absent(),
    this.streak = const Value.absent(),
    this.consolidated = const Value.absent(),
    this.lastPassed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewItemRowsCompanion.insert({
    required String id,
    required String sourceType,
    required String sourceId,
    required String textEn,
    this.textZh = const Value.absent(),
    required int dueAt,
    required int stage,
    required int streak,
    required int consolidated,
    this.lastPassed = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceType = Value(sourceType),
       sourceId = Value(sourceId),
       textEn = Value(textEn),
       dueAt = Value(dueAt),
       stage = Value(stage),
       streak = Value(streak),
       consolidated = Value(consolidated),
       createdAt = Value(createdAt);
  static Insertable<ReviewItemRow> custom({
    Expression<String>? id,
    Expression<String>? sourceType,
    Expression<String>? sourceId,
    Expression<String>? textEn,
    Expression<String>? textZh,
    Expression<int>? dueAt,
    Expression<int>? stage,
    Expression<int>? streak,
    Expression<int>? consolidated,
    Expression<int>? lastPassed,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (textEn != null) 'text_en': textEn,
      if (textZh != null) 'text_zh': textZh,
      if (dueAt != null) 'due_at': dueAt,
      if (stage != null) 'stage': stage,
      if (streak != null) 'streak': streak,
      if (consolidated != null) 'consolidated': consolidated,
      if (lastPassed != null) 'last_passed': lastPassed,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewItemRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceType,
    Value<String>? sourceId,
    Value<String>? textEn,
    Value<String?>? textZh,
    Value<int>? dueAt,
    Value<int>? stage,
    Value<int>? streak,
    Value<int>? consolidated,
    Value<int?>? lastPassed,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return ReviewItemRowsCompanion(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      textEn: textEn ?? this.textEn,
      textZh: textZh ?? this.textZh,
      dueAt: dueAt ?? this.dueAt,
      stage: stage ?? this.stage,
      streak: streak ?? this.streak,
      consolidated: consolidated ?? this.consolidated,
      lastPassed: lastPassed ?? this.lastPassed,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (textEn.present) {
      map['text_en'] = Variable<String>(textEn.value);
    }
    if (textZh.present) {
      map['text_zh'] = Variable<String>(textZh.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (stage.present) {
      map['stage'] = Variable<int>(stage.value);
    }
    if (streak.present) {
      map['streak'] = Variable<int>(streak.value);
    }
    if (consolidated.present) {
      map['consolidated'] = Variable<int>(consolidated.value);
    }
    if (lastPassed.present) {
      map['last_passed'] = Variable<int>(lastPassed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewItemRowsCompanion(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('textEn: $textEn, ')
          ..write('textZh: $textZh, ')
          ..write('dueAt: $dueAt, ')
          ..write('stage: $stage, ')
          ..write('streak: $streak, ')
          ..write('consolidated: $consolidated, ')
          ..write('lastPassed: $lastPassed, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScenariosTable scenarios = $ScenariosTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $CorrectionsTable corrections = $CorrectionsTable(this);
  late final $PhrasesTable phrases = $PhrasesTable(this);
  late final $LlmProfilesTable llmProfiles = $LlmProfilesTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final $TtsCachesTable ttsCaches = $TtsCachesTable(this);
  late final $AppMetasTable appMetas = $AppMetasTable(this);
  late final $MaterialsTable materials = $MaterialsTable(this);
  late final $MaterialSegmentsTable materialSegments = $MaterialSegmentsTable(
    this,
  );
  late final $DictationAttemptsTable dictationAttempts =
      $DictationAttemptsTable(this);
  late final $ReviewItemRowsTable reviewItemRows = $ReviewItemRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    scenarios,
    sessions,
    messages,
    corrections,
    phrases,
    llmProfiles,
    settingsTable,
    ttsCaches,
    appMetas,
    materials,
    materialSegments,
    dictationAttempts,
    reviewItemRows,
  ];
}

typedef $$ScenariosTableCreateCompanionBuilder = ScenariosCompanion Function({
  required String id,
  required String titleZh,
  required String titleEn,
  required String category,
  required String level,
  required String aiRole,
  required String userGoal,
  required String openingLine,
  required String targetPhrases,
  required int expectedTurns,
  required String successCriteria,
  Value<String?> branchHint,
  required int isBuiltin,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$ScenariosTableUpdateCompanionBuilder = ScenariosCompanion Function({
  Value<String> id,
  Value<String> titleZh,
  Value<String> titleEn,
  Value<String> category,
  Value<String> level,
  Value<String> aiRole,
  Value<String> userGoal,
  Value<String> openingLine,
  Value<String> targetPhrases,
  Value<int> expectedTurns,
  Value<String> successCriteria,
  Value<String?> branchHint,
  Value<int> isBuiltin,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$ScenariosTableFilterComposer
    extends Composer<_$AppDatabase, $ScenariosTable> {
  $$ScenariosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleZh => $composableBuilder(
    column: $table.titleZh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleEn => $composableBuilder(
    column: $table.titleEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiRole => $composableBuilder(
    column: $table.aiRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userGoal => $composableBuilder(
    column: $table.userGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openingLine => $composableBuilder(
    column: $table.openingLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetPhrases => $composableBuilder(
    column: $table.targetPhrases,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedTurns => $composableBuilder(
    column: $table.expectedTurns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get successCriteria => $composableBuilder(
    column: $table.successCriteria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchHint => $composableBuilder(
    column: $table.branchHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScenariosTableOrderingComposer
    extends Composer<_$AppDatabase, $ScenariosTable> {
  $$ScenariosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleZh => $composableBuilder(
    column: $table.titleZh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleEn => $composableBuilder(
    column: $table.titleEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiRole => $composableBuilder(
    column: $table.aiRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userGoal => $composableBuilder(
    column: $table.userGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openingLine => $composableBuilder(
    column: $table.openingLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetPhrases => $composableBuilder(
    column: $table.targetPhrases,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedTurns => $composableBuilder(
    column: $table.expectedTurns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get successCriteria => $composableBuilder(
    column: $table.successCriteria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchHint => $composableBuilder(
    column: $table.branchHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScenariosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScenariosTable> {
  $$ScenariosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get titleZh =>
      $composableBuilder(column: $table.titleZh, builder: (column) => column);

  GeneratedColumn<String> get titleEn =>
      $composableBuilder(column: $table.titleEn, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get aiRole =>
      $composableBuilder(column: $table.aiRole, builder: (column) => column);

  GeneratedColumn<String> get userGoal =>
      $composableBuilder(column: $table.userGoal, builder: (column) => column);

  GeneratedColumn<String> get openingLine => $composableBuilder(
    column: $table.openingLine,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetPhrases => $composableBuilder(
    column: $table.targetPhrases,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expectedTurns => $composableBuilder(
    column: $table.expectedTurns,
    builder: (column) => column,
  );

  GeneratedColumn<String> get successCriteria => $composableBuilder(
    column: $table.successCriteria,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchHint => $composableBuilder(
    column: $table.branchHint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isBuiltin =>
      $composableBuilder(column: $table.isBuiltin, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ScenariosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScenariosTable,
          Scenario,
          $$ScenariosTableFilterComposer,
          $$ScenariosTableOrderingComposer,
          $$ScenariosTableAnnotationComposer,
          $$ScenariosTableCreateCompanionBuilder,
          $$ScenariosTableUpdateCompanionBuilder,
          (Scenario, BaseReferences<_$AppDatabase, $ScenariosTable, Scenario>),
          Scenario,
          PrefetchHooks Function()
        > {
  $$ScenariosTableTableManager(_$AppDatabase db, $ScenariosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScenariosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScenariosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScenariosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> titleZh = const Value.absent(),
                Value<String> titleEn = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String> aiRole = const Value.absent(),
                Value<String> userGoal = const Value.absent(),
                Value<String> openingLine = const Value.absent(),
                Value<String> targetPhrases = const Value.absent(),
                Value<int> expectedTurns = const Value.absent(),
                Value<String> successCriteria = const Value.absent(),
                Value<String?> branchHint = const Value.absent(),
                Value<int> isBuiltin = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScenariosCompanion(
                id: id,
                titleZh: titleZh,
                titleEn: titleEn,
                category: category,
                level: level,
                aiRole: aiRole,
                userGoal: userGoal,
                openingLine: openingLine,
                targetPhrases: targetPhrases,
                expectedTurns: expectedTurns,
                successCriteria: successCriteria,
                branchHint: branchHint,
                isBuiltin: isBuiltin,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String titleZh,
                required String titleEn,
                required String category,
                required String level,
                required String aiRole,
                required String userGoal,
                required String openingLine,
                required String targetPhrases,
                required int expectedTurns,
                required String successCriteria,
                Value<String?> branchHint = const Value.absent(),
                required int isBuiltin,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => ScenariosCompanion.insert(
                id: id,
                titleZh: titleZh,
                titleEn: titleEn,
                category: category,
                level: level,
                aiRole: aiRole,
                userGoal: userGoal,
                openingLine: openingLine,
                targetPhrases: targetPhrases,
                expectedTurns: expectedTurns,
                successCriteria: successCriteria,
                branchHint: branchHint,
                isBuiltin: isBuiltin,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScenariosTable, Scenario>(table),
                  BaseReferences<_$AppDatabase, $ScenariosTable, Scenario>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScenariosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScenariosTable,
      Scenario,
      $$ScenariosTableFilterComposer,
      $$ScenariosTableOrderingComposer,
      $$ScenariosTableAnnotationComposer,
      $$ScenariosTableCreateCompanionBuilder,
      $$ScenariosTableUpdateCompanionBuilder,
      (Scenario, BaseReferences<_$AppDatabase, $ScenariosTable, Scenario>),
      Scenario,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  Value<String?> scenarioId,
  required int startedAt,
  Value<int?> endedAt,
  required int durationSec,
  required int turnCount,
  required int hintCount,
  required int assistTurns,
  required int translateCount,
  required String status,
  Value<String?> modelName,
  Value<String?> ttsEngine,
  Value<String?> reviewJson,
  Value<double?> costEstimate,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<String?> scenarioId,
  Value<int> startedAt,
  Value<int?> endedAt,
  Value<int> durationSec,
  Value<int> turnCount,
  Value<int> hintCount,
  Value<int> assistTurns,
  Value<int> translateCount,
  Value<String> status,
  Value<String?> modelName,
  Value<String?> ttsEngine,
  Value<String?> reviewJson,
  Value<double?> costEstimate,
  Value<int> rowid,
});

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scenarioId => $composableBuilder(
    column: $table.scenarioId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get turnCount => $composableBuilder(
    column: $table.turnCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintCount => $composableBuilder(
    column: $table.hintCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get assistTurns => $composableBuilder(
    column: $table.assistTurns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get translateCount => $composableBuilder(
    column: $table.translateCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ttsEngine => $composableBuilder(
    column: $table.ttsEngine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewJson => $composableBuilder(
    column: $table.reviewJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costEstimate => $composableBuilder(
    column: $table.costEstimate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scenarioId => $composableBuilder(
    column: $table.scenarioId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get turnCount => $composableBuilder(
    column: $table.turnCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintCount => $composableBuilder(
    column: $table.hintCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get assistTurns => $composableBuilder(
    column: $table.assistTurns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get translateCount => $composableBuilder(
    column: $table.translateCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ttsEngine => $composableBuilder(
    column: $table.ttsEngine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewJson => $composableBuilder(
    column: $table.reviewJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costEstimate => $composableBuilder(
    column: $table.costEstimate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scenarioId => $composableBuilder(
    column: $table.scenarioId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get turnCount =>
      $composableBuilder(column: $table.turnCount, builder: (column) => column);

  GeneratedColumn<int> get hintCount =>
      $composableBuilder(column: $table.hintCount, builder: (column) => column);

  GeneratedColumn<int> get assistTurns => $composableBuilder(
    column: $table.assistTurns,
    builder: (column) => column,
  );

  GeneratedColumn<int> get translateCount => $composableBuilder(
    column: $table.translateCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get ttsEngine =>
      $composableBuilder(column: $table.ttsEngine, builder: (column) => column);

  GeneratedColumn<String> get reviewJson => $composableBuilder(
    column: $table.reviewJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costEstimate => $composableBuilder(
    column: $table.costEstimate,
    builder: (column) => column,
  );
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> scenarioId = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> endedAt = const Value.absent(),
                Value<int> durationSec = const Value.absent(),
                Value<int> turnCount = const Value.absent(),
                Value<int> hintCount = const Value.absent(),
                Value<int> assistTurns = const Value.absent(),
                Value<int> translateCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> ttsEngine = const Value.absent(),
                Value<String?> reviewJson = const Value.absent(),
                Value<double?> costEstimate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                scenarioId: scenarioId,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSec: durationSec,
                turnCount: turnCount,
                hintCount: hintCount,
                assistTurns: assistTurns,
                translateCount: translateCount,
                status: status,
                modelName: modelName,
                ttsEngine: ttsEngine,
                reviewJson: reviewJson,
                costEstimate: costEstimate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> scenarioId = const Value.absent(),
                required int startedAt,
                Value<int?> endedAt = const Value.absent(),
                required int durationSec,
                required int turnCount,
                required int hintCount,
                required int assistTurns,
                required int translateCount,
                required String status,
                Value<String?> modelName = const Value.absent(),
                Value<String?> ttsEngine = const Value.absent(),
                Value<String?> reviewJson = const Value.absent(),
                Value<double?> costEstimate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                scenarioId: scenarioId,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSec: durationSec,
                turnCount: turnCount,
                hintCount: hintCount,
                assistTurns: assistTurns,
                translateCount: translateCount,
                status: status,
                modelName: modelName,
                ttsEngine: ttsEngine,
                reviewJson: reviewJson,
                costEstimate: costEstimate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, Session>(table),
                  BaseReferences<_$AppDatabase, $SessionsTable, Session>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  required String id,
  required String sessionId,
  required int seq,
  required String role,
  required String textEn,
  Value<String?> textZh,
  Value<String?> audioPath,
  Value<String?> asrProvider,
  Value<int?> latencyMs,
  required int isHint,
  Value<int?> hintLevel,
  required String status,
  required int createdAt,
  Value<int> rowid,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<String> id,
  Value<String> sessionId,
  Value<int> seq,
  Value<String> role,
  Value<String> textEn,
  Value<String?> textZh,
  Value<String?> audioPath,
  Value<String?> asrProvider,
  Value<int?> latencyMs,
  Value<int> isHint,
  Value<int?> hintLevel,
  Value<String> status,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textEn => $composableBuilder(
    column: $table.textEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textZh => $composableBuilder(
    column: $table.textZh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get asrProvider => $composableBuilder(
    column: $table.asrProvider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latencyMs => $composableBuilder(
    column: $table.latencyMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isHint => $composableBuilder(
    column: $table.isHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintLevel => $composableBuilder(
    column: $table.hintLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textEn => $composableBuilder(
    column: $table.textEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textZh => $composableBuilder(
    column: $table.textZh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get asrProvider => $composableBuilder(
    column: $table.asrProvider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latencyMs => $composableBuilder(
    column: $table.latencyMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isHint => $composableBuilder(
    column: $table.isHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintLevel => $composableBuilder(
    column: $table.hintLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get textEn =>
      $composableBuilder(column: $table.textEn, builder: (column) => column);

  GeneratedColumn<String> get textZh =>
      $composableBuilder(column: $table.textZh, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<String> get asrProvider => $composableBuilder(
    column: $table.asrProvider,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latencyMs =>
      $composableBuilder(column: $table.latencyMs, builder: (column) => column);

  GeneratedColumn<int> get isHint =>
      $composableBuilder(column: $table.isHint, builder: (column) => column);

  GeneratedColumn<int> get hintLevel =>
      $composableBuilder(column: $table.hintLevel, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> textEn = const Value.absent(),
                Value<String?> textZh = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<String?> asrProvider = const Value.absent(),
                Value<int?> latencyMs = const Value.absent(),
                Value<int> isHint = const Value.absent(),
                Value<int?> hintLevel = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                sessionId: sessionId,
                seq: seq,
                role: role,
                textEn: textEn,
                textZh: textZh,
                audioPath: audioPath,
                asrProvider: asrProvider,
                latencyMs: latencyMs,
                isHint: isHint,
                hintLevel: hintLevel,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required int seq,
                required String role,
                required String textEn,
                Value<String?> textZh = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<String?> asrProvider = const Value.absent(),
                Value<int?> latencyMs = const Value.absent(),
                required int isHint,
                Value<int?> hintLevel = const Value.absent(),
                required String status,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                sessionId: sessionId,
                seq: seq,
                role: role,
                textEn: textEn,
                textZh: textZh,
                audioPath: audioPath,
                asrProvider: asrProvider,
                latencyMs: latencyMs,
                isHint: isHint,
                hintLevel: hintLevel,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MessagesTable, Message>(table),
                  BaseReferences<_$AppDatabase, $MessagesTable, Message>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$CorrectionsTableCreateCompanionBuilder =
    CorrectionsCompanion Function({
      required String id,
      required String sessionId,
      required String messageId,
      required String original,
      required String improved,
      required String reasonZh,
      Value<String?> audioPath,
      required int isDeleted,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$CorrectionsTableUpdateCompanionBuilder =
    CorrectionsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> messageId,
      Value<String> original,
      Value<String> improved,
      Value<String> reasonZh,
      Value<String?> audioPath,
      Value<int> isDeleted,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$CorrectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CorrectionsTable> {
  $$CorrectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get original => $composableBuilder(
    column: $table.original,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get improved => $composableBuilder(
    column: $table.improved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonZh => $composableBuilder(
    column: $table.reasonZh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CorrectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CorrectionsTable> {
  $$CorrectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get original => $composableBuilder(
    column: $table.original,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get improved => $composableBuilder(
    column: $table.improved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonZh => $composableBuilder(
    column: $table.reasonZh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CorrectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CorrectionsTable> {
  $$CorrectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get original =>
      $composableBuilder(column: $table.original, builder: (column) => column);

  GeneratedColumn<String> get improved =>
      $composableBuilder(column: $table.improved, builder: (column) => column);

  GeneratedColumn<String> get reasonZh =>
      $composableBuilder(column: $table.reasonZh, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CorrectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CorrectionsTable,
          Correction,
          $$CorrectionsTableFilterComposer,
          $$CorrectionsTableOrderingComposer,
          $$CorrectionsTableAnnotationComposer,
          $$CorrectionsTableCreateCompanionBuilder,
          $$CorrectionsTableUpdateCompanionBuilder,
          (
            Correction,
            BaseReferences<_$AppDatabase, $CorrectionsTable, Correction>,
          ),
          Correction,
          PrefetchHooks Function()
        > {
  $$CorrectionsTableTableManager(_$AppDatabase db, $CorrectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CorrectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CorrectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CorrectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<String> original = const Value.absent(),
                Value<String> improved = const Value.absent(),
                Value<String> reasonZh = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CorrectionsCompanion(
                id: id,
                sessionId: sessionId,
                messageId: messageId,
                original: original,
                improved: improved,
                reasonZh: reasonZh,
                audioPath: audioPath,
                isDeleted: isDeleted,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String messageId,
                required String original,
                required String improved,
                required String reasonZh,
                Value<String?> audioPath = const Value.absent(),
                required int isDeleted,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CorrectionsCompanion.insert(
                id: id,
                sessionId: sessionId,
                messageId: messageId,
                original: original,
                improved: improved,
                reasonZh: reasonZh,
                audioPath: audioPath,
                isDeleted: isDeleted,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CorrectionsTable, Correction>(table),
                  BaseReferences<_$AppDatabase, $CorrectionsTable, Correction>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CorrectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CorrectionsTable,
      Correction,
      $$CorrectionsTableFilterComposer,
      $$CorrectionsTableOrderingComposer,
      $$CorrectionsTableAnnotationComposer,
      $$CorrectionsTableCreateCompanionBuilder,
      $$CorrectionsTableUpdateCompanionBuilder,
      (
        Correction,
        BaseReferences<_$AppDatabase, $CorrectionsTable, Correction>,
      ),
      Correction,
      PrefetchHooks Function()
    >;
typedef $$PhrasesTableCreateCompanionBuilder = PhrasesCompanion Function({
  required String id,
  required String textEn,
  Value<String?> textZh,
  Value<String?> sourceSessionId,
  Value<String?> sourceScenarioId,
  Value<String?> audioPath,
  required int mastered,
  required int createdAt,
  Value<int> rowid,
});
typedef $$PhrasesTableUpdateCompanionBuilder = PhrasesCompanion Function({
  Value<String> id,
  Value<String> textEn,
  Value<String?> textZh,
  Value<String?> sourceSessionId,
  Value<String?> sourceScenarioId,
  Value<String?> audioPath,
  Value<int> mastered,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$PhrasesTableFilterComposer
    extends Composer<_$AppDatabase, $PhrasesTable> {
  $$PhrasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textEn => $composableBuilder(
    column: $table.textEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textZh => $composableBuilder(
    column: $table.textZh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceSessionId => $composableBuilder(
    column: $table.sourceSessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceScenarioId => $composableBuilder(
    column: $table.sourceScenarioId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mastered => $composableBuilder(
    column: $table.mastered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhrasesTableOrderingComposer
    extends Composer<_$AppDatabase, $PhrasesTable> {
  $$PhrasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textEn => $composableBuilder(
    column: $table.textEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textZh => $composableBuilder(
    column: $table.textZh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceSessionId => $composableBuilder(
    column: $table.sourceSessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceScenarioId => $composableBuilder(
    column: $table.sourceScenarioId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mastered => $composableBuilder(
    column: $table.mastered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhrasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhrasesTable> {
  $$PhrasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get textEn =>
      $composableBuilder(column: $table.textEn, builder: (column) => column);

  GeneratedColumn<String> get textZh =>
      $composableBuilder(column: $table.textZh, builder: (column) => column);

  GeneratedColumn<String> get sourceSessionId => $composableBuilder(
    column: $table.sourceSessionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceScenarioId => $composableBuilder(
    column: $table.sourceScenarioId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<int> get mastered =>
      $composableBuilder(column: $table.mastered, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PhrasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhrasesTable,
          Phrase,
          $$PhrasesTableFilterComposer,
          $$PhrasesTableOrderingComposer,
          $$PhrasesTableAnnotationComposer,
          $$PhrasesTableCreateCompanionBuilder,
          $$PhrasesTableUpdateCompanionBuilder,
          (Phrase, BaseReferences<_$AppDatabase, $PhrasesTable, Phrase>),
          Phrase,
          PrefetchHooks Function()
        > {
  $$PhrasesTableTableManager(_$AppDatabase db, $PhrasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhrasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhrasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhrasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> textEn = const Value.absent(),
                Value<String?> textZh = const Value.absent(),
                Value<String?> sourceSessionId = const Value.absent(),
                Value<String?> sourceScenarioId = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<int> mastered = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhrasesCompanion(
                id: id,
                textEn: textEn,
                textZh: textZh,
                sourceSessionId: sourceSessionId,
                sourceScenarioId: sourceScenarioId,
                audioPath: audioPath,
                mastered: mastered,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String textEn,
                Value<String?> textZh = const Value.absent(),
                Value<String?> sourceSessionId = const Value.absent(),
                Value<String?> sourceScenarioId = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                required int mastered,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PhrasesCompanion.insert(
                id: id,
                textEn: textEn,
                textZh: textZh,
                sourceSessionId: sourceSessionId,
                sourceScenarioId: sourceScenarioId,
                audioPath: audioPath,
                mastered: mastered,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PhrasesTable, Phrase>(table),
                  BaseReferences<_$AppDatabase, $PhrasesTable, Phrase>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhrasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhrasesTable,
      Phrase,
      $$PhrasesTableFilterComposer,
      $$PhrasesTableOrderingComposer,
      $$PhrasesTableAnnotationComposer,
      $$PhrasesTableCreateCompanionBuilder,
      $$PhrasesTableUpdateCompanionBuilder,
      (Phrase, BaseReferences<_$AppDatabase, $PhrasesTable, Phrase>),
      Phrase,
      PrefetchHooks Function()
    >;
typedef $$LlmProfilesTableCreateCompanionBuilder =
    LlmProfilesCompanion Function({
      required String id,
      required String name,
      required String baseUrl,
      required String model,
      required String keyRef,
      Value<String?> extraJson,
      Value<String?> lastCheckStatus,
      Value<String?> lastCheckMessage,
      Value<int?> lastCheckedAt,
      required int isActive,
      Value<int> rowid,
    });
typedef $$LlmProfilesTableUpdateCompanionBuilder =
    LlmProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> baseUrl,
      Value<String> model,
      Value<String> keyRef,
      Value<String?> extraJson,
      Value<String?> lastCheckStatus,
      Value<String?> lastCheckMessage,
      Value<int?> lastCheckedAt,
      Value<int> isActive,
      Value<int> rowid,
    });

class $$LlmProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $LlmProfilesTable> {
  $$LlmProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyRef => $composableBuilder(
    column: $table.keyRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extraJson => $composableBuilder(
    column: $table.extraJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastCheckStatus => $composableBuilder(
    column: $table.lastCheckStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastCheckMessage => $composableBuilder(
    column: $table.lastCheckMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LlmProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $LlmProfilesTable> {
  $$LlmProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyRef => $composableBuilder(
    column: $table.keyRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extraJson => $composableBuilder(
    column: $table.extraJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastCheckStatus => $composableBuilder(
    column: $table.lastCheckStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastCheckMessage => $composableBuilder(
    column: $table.lastCheckMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LlmProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LlmProfilesTable> {
  $$LlmProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get keyRef =>
      $composableBuilder(column: $table.keyRef, builder: (column) => column);

  GeneratedColumn<String> get extraJson =>
      $composableBuilder(column: $table.extraJson, builder: (column) => column);

  GeneratedColumn<String> get lastCheckStatus => $composableBuilder(
    column: $table.lastCheckStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastCheckMessage => $composableBuilder(
    column: $table.lastCheckMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$LlmProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LlmProfilesTable,
          LlmProfile,
          $$LlmProfilesTableFilterComposer,
          $$LlmProfilesTableOrderingComposer,
          $$LlmProfilesTableAnnotationComposer,
          $$LlmProfilesTableCreateCompanionBuilder,
          $$LlmProfilesTableUpdateCompanionBuilder,
          (
            LlmProfile,
            BaseReferences<_$AppDatabase, $LlmProfilesTable, LlmProfile>,
          ),
          LlmProfile,
          PrefetchHooks Function()
        > {
  $$LlmProfilesTableTableManager(_$AppDatabase db, $LlmProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LlmProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LlmProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LlmProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> keyRef = const Value.absent(),
                Value<String?> extraJson = const Value.absent(),
                Value<String?> lastCheckStatus = const Value.absent(),
                Value<String?> lastCheckMessage = const Value.absent(),
                Value<int?> lastCheckedAt = const Value.absent(),
                Value<int> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LlmProfilesCompanion(
                id: id,
                name: name,
                baseUrl: baseUrl,
                model: model,
                keyRef: keyRef,
                extraJson: extraJson,
                lastCheckStatus: lastCheckStatus,
                lastCheckMessage: lastCheckMessage,
                lastCheckedAt: lastCheckedAt,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String baseUrl,
                required String model,
                required String keyRef,
                Value<String?> extraJson = const Value.absent(),
                Value<String?> lastCheckStatus = const Value.absent(),
                Value<String?> lastCheckMessage = const Value.absent(),
                Value<int?> lastCheckedAt = const Value.absent(),
                required int isActive,
                Value<int> rowid = const Value.absent(),
              }) => LlmProfilesCompanion.insert(
                id: id,
                name: name,
                baseUrl: baseUrl,
                model: model,
                keyRef: keyRef,
                extraJson: extraJson,
                lastCheckStatus: lastCheckStatus,
                lastCheckMessage: lastCheckMessage,
                lastCheckedAt: lastCheckedAt,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LlmProfilesTable, LlmProfile>(table),
                  BaseReferences<_$AppDatabase, $LlmProfilesTable, LlmProfile>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LlmProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LlmProfilesTable,
      LlmProfile,
      $$LlmProfilesTableFilterComposer,
      $$LlmProfilesTableOrderingComposer,
      $$LlmProfilesTableAnnotationComposer,
      $$LlmProfilesTableCreateCompanionBuilder,
      $$LlmProfilesTableUpdateCompanionBuilder,
      (
        LlmProfile,
        BaseReferences<_$AppDatabase, $LlmProfilesTable, LlmProfile>,
      ),
      LlmProfile,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableTableCreateCompanionBuilder =
    SettingsTableCompanion Function({
      required String key,
      required String value,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$SettingsTableTableUpdateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTableTable,
          SettingsTableData,
          $$SettingsTableTableFilterComposer,
          $$SettingsTableTableOrderingComposer,
          $$SettingsTableTableAnnotationComposer,
          $$SettingsTableTableCreateCompanionBuilder,
          $$SettingsTableTableUpdateCompanionBuilder,
          (
            SettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $SettingsTableTable,
              SettingsTableData
            >,
          ),
          SettingsTableData,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTableTable, SettingsTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SettingsTableTable,
                    SettingsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTableTable,
      SettingsTableData,
      $$SettingsTableTableFilterComposer,
      $$SettingsTableTableOrderingComposer,
      $$SettingsTableTableAnnotationComposer,
      $$SettingsTableTableCreateCompanionBuilder,
      $$SettingsTableTableUpdateCompanionBuilder,
      (
        SettingsTableData,
        BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsTableData>,
      ),
      SettingsTableData,
      PrefetchHooks Function()
    >;
typedef $$TtsCachesTableCreateCompanionBuilder = TtsCachesCompanion Function({
  required String hash,
  required String engine,
  required String voice,
  required double rate,
  required String filePath,
  required int bytes,
  required int createdAt,
  required int lastUsedAt,
  Value<int> rowid,
});
typedef $$TtsCachesTableUpdateCompanionBuilder = TtsCachesCompanion Function({
  Value<String> hash,
  Value<String> engine,
  Value<String> voice,
  Value<double> rate,
  Value<String> filePath,
  Value<int> bytes,
  Value<int> createdAt,
  Value<int> lastUsedAt,
  Value<int> rowid,
});

class $$TtsCachesTableFilterComposer
    extends Composer<_$AppDatabase, $TtsCachesTable> {
  $$TtsCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get engine => $composableBuilder(
    column: $table.engine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voice => $composableBuilder(
    column: $table.voice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TtsCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $TtsCachesTable> {
  $$TtsCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get engine => $composableBuilder(
    column: $table.engine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voice => $composableBuilder(
    column: $table.voice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TtsCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TtsCachesTable> {
  $$TtsCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get engine =>
      $composableBuilder(column: $table.engine, builder: (column) => column);

  GeneratedColumn<String> get voice =>
      $composableBuilder(column: $table.voice, builder: (column) => column);

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $$TtsCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TtsCachesTable,
          TtsCache,
          $$TtsCachesTableFilterComposer,
          $$TtsCachesTableOrderingComposer,
          $$TtsCachesTableAnnotationComposer,
          $$TtsCachesTableCreateCompanionBuilder,
          $$TtsCachesTableUpdateCompanionBuilder,
          (TtsCache, BaseReferences<_$AppDatabase, $TtsCachesTable, TtsCache>),
          TtsCache,
          PrefetchHooks Function()
        > {
  $$TtsCachesTableTableManager(_$AppDatabase db, $TtsCachesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TtsCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TtsCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TtsCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> hash = const Value.absent(),
                Value<String> engine = const Value.absent(),
                Value<String> voice = const Value.absent(),
                Value<double> rate = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> bytes = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TtsCachesCompanion(
                hash: hash,
                engine: engine,
                voice: voice,
                rate: rate,
                filePath: filePath,
                bytes: bytes,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String hash,
                required String engine,
                required String voice,
                required double rate,
                required String filePath,
                required int bytes,
                required int createdAt,
                required int lastUsedAt,
                Value<int> rowid = const Value.absent(),
              }) => TtsCachesCompanion.insert(
                hash: hash,
                engine: engine,
                voice: voice,
                rate: rate,
                filePath: filePath,
                bytes: bytes,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TtsCachesTable, TtsCache>(table),
                  BaseReferences<_$AppDatabase, $TtsCachesTable, TtsCache>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TtsCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TtsCachesTable,
      TtsCache,
      $$TtsCachesTableFilterComposer,
      $$TtsCachesTableOrderingComposer,
      $$TtsCachesTableAnnotationComposer,
      $$TtsCachesTableCreateCompanionBuilder,
      $$TtsCachesTableUpdateCompanionBuilder,
      (TtsCache, BaseReferences<_$AppDatabase, $TtsCachesTable, TtsCache>),
      TtsCache,
      PrefetchHooks Function()
    >;
typedef $$AppMetasTableCreateCompanionBuilder = AppMetasCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppMetasTableUpdateCompanionBuilder = AppMetasCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppMetasTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetasTable> {
  $$AppMetasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetasTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetasTable> {
  $$AppMetasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetasTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetasTable> {
  $$AppMetasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetasTable,
          AppMeta,
          $$AppMetasTableFilterComposer,
          $$AppMetasTableOrderingComposer,
          $$AppMetasTableAnnotationComposer,
          $$AppMetasTableCreateCompanionBuilder,
          $$AppMetasTableUpdateCompanionBuilder,
          (AppMeta, BaseReferences<_$AppDatabase, $AppMetasTable, AppMeta>),
          AppMeta,
          PrefetchHooks Function()
        > {
  $$AppMetasTableTableManager(_$AppDatabase db, $AppMetasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppMetasCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => AppMetasCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppMetasTable, AppMeta>(table),
                  BaseReferences<_$AppDatabase, $AppMetasTable, AppMeta>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetasTable,
      AppMeta,
      $$AppMetasTableFilterComposer,
      $$AppMetasTableOrderingComposer,
      $$AppMetasTableAnnotationComposer,
      $$AppMetasTableCreateCompanionBuilder,
      $$AppMetasTableUpdateCompanionBuilder,
      (AppMeta, BaseReferences<_$AppDatabase, $AppMetasTable, AppMeta>),
      AppMeta,
      PrefetchHooks Function()
    >;
typedef $$MaterialsTableCreateCompanionBuilder = MaterialsCompanion Function({
  required String id,
  required String title,
  required String mediaPath,
  required String mediaName,
  required String mediaKind,
  required String subtitleName,
  required String sourceHash,
  required int durationMs,
  required int segmentCount,
  required int createdAt,
  Value<int?> lastPracticedAt,
  Value<int> rowid,
});
typedef $$MaterialsTableUpdateCompanionBuilder = MaterialsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> mediaPath,
  Value<String> mediaName,
  Value<String> mediaKind,
  Value<String> subtitleName,
  Value<String> sourceHash,
  Value<int> durationMs,
  Value<int> segmentCount,
  Value<int> createdAt,
  Value<int?> lastPracticedAt,
  Value<int> rowid,
});

class $$MaterialsTableFilterComposer
    extends Composer<_$AppDatabase, $MaterialsTable> {
  $$MaterialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaPath => $composableBuilder(
    column: $table.mediaPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaName => $composableBuilder(
    column: $table.mediaName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaKind => $composableBuilder(
    column: $table.mediaKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitleName => $composableBuilder(
    column: $table.subtitleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceHash => $composableBuilder(
    column: $table.sourceHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segmentCount => $composableBuilder(
    column: $table.segmentCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPracticedAt => $composableBuilder(
    column: $table.lastPracticedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MaterialsTableOrderingComposer
    extends Composer<_$AppDatabase, $MaterialsTable> {
  $$MaterialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaPath => $composableBuilder(
    column: $table.mediaPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaName => $composableBuilder(
    column: $table.mediaName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaKind => $composableBuilder(
    column: $table.mediaKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitleName => $composableBuilder(
    column: $table.subtitleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceHash => $composableBuilder(
    column: $table.sourceHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segmentCount => $composableBuilder(
    column: $table.segmentCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPracticedAt => $composableBuilder(
    column: $table.lastPracticedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MaterialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaterialsTable> {
  $$MaterialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get mediaPath =>
      $composableBuilder(column: $table.mediaPath, builder: (column) => column);

  GeneratedColumn<String> get mediaName =>
      $composableBuilder(column: $table.mediaName, builder: (column) => column);

  GeneratedColumn<String> get mediaKind =>
      $composableBuilder(column: $table.mediaKind, builder: (column) => column);

  GeneratedColumn<String> get subtitleName => $composableBuilder(
    column: $table.subtitleName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceHash => $composableBuilder(
    column: $table.sourceHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get segmentCount => $composableBuilder(
    column: $table.segmentCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastPracticedAt => $composableBuilder(
    column: $table.lastPracticedAt,
    builder: (column) => column,
  );
}

class $$MaterialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaterialsTable,
          Material,
          $$MaterialsTableFilterComposer,
          $$MaterialsTableOrderingComposer,
          $$MaterialsTableAnnotationComposer,
          $$MaterialsTableCreateCompanionBuilder,
          $$MaterialsTableUpdateCompanionBuilder,
          (Material, BaseReferences<_$AppDatabase, $MaterialsTable, Material>),
          Material,
          PrefetchHooks Function()
        > {
  $$MaterialsTableTableManager(_$AppDatabase db, $MaterialsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaterialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaterialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaterialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> mediaPath = const Value.absent(),
                Value<String> mediaName = const Value.absent(),
                Value<String> mediaKind = const Value.absent(),
                Value<String> subtitleName = const Value.absent(),
                Value<String> sourceHash = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> segmentCount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> lastPracticedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaterialsCompanion(
                id: id,
                title: title,
                mediaPath: mediaPath,
                mediaName: mediaName,
                mediaKind: mediaKind,
                subtitleName: subtitleName,
                sourceHash: sourceHash,
                durationMs: durationMs,
                segmentCount: segmentCount,
                createdAt: createdAt,
                lastPracticedAt: lastPracticedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String mediaPath,
                required String mediaName,
                required String mediaKind,
                required String subtitleName,
                required String sourceHash,
                required int durationMs,
                required int segmentCount,
                required int createdAt,
                Value<int?> lastPracticedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaterialsCompanion.insert(
                id: id,
                title: title,
                mediaPath: mediaPath,
                mediaName: mediaName,
                mediaKind: mediaKind,
                subtitleName: subtitleName,
                sourceHash: sourceHash,
                durationMs: durationMs,
                segmentCount: segmentCount,
                createdAt: createdAt,
                lastPracticedAt: lastPracticedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MaterialsTable, Material>(table),
                  BaseReferences<_$AppDatabase, $MaterialsTable, Material>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MaterialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaterialsTable,
      Material,
      $$MaterialsTableFilterComposer,
      $$MaterialsTableOrderingComposer,
      $$MaterialsTableAnnotationComposer,
      $$MaterialsTableCreateCompanionBuilder,
      $$MaterialsTableUpdateCompanionBuilder,
      (Material, BaseReferences<_$AppDatabase, $MaterialsTable, Material>),
      Material,
      PrefetchHooks Function()
    >;
typedef $$MaterialSegmentsTableCreateCompanionBuilder =
    MaterialSegmentsCompanion Function({
      required String id,
      required String materialId,
      required int seq,
      required String textEn,
      required int startMs,
      required int endMs,
      required int wordCount,
      required int isHard,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$MaterialSegmentsTableUpdateCompanionBuilder =
    MaterialSegmentsCompanion Function({
      Value<String> id,
      Value<String> materialId,
      Value<int> seq,
      Value<String> textEn,
      Value<int> startMs,
      Value<int> endMs,
      Value<int> wordCount,
      Value<int> isHard,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$MaterialSegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $MaterialSegmentsTable> {
  $$MaterialSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get materialId => $composableBuilder(
    column: $table.materialId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textEn => $composableBuilder(
    column: $table.textEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isHard => $composableBuilder(
    column: $table.isHard,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MaterialSegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $MaterialSegmentsTable> {
  $$MaterialSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get materialId => $composableBuilder(
    column: $table.materialId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textEn => $composableBuilder(
    column: $table.textEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isHard => $composableBuilder(
    column: $table.isHard,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MaterialSegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaterialSegmentsTable> {
  $$MaterialSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get materialId => $composableBuilder(
    column: $table.materialId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get textEn =>
      $composableBuilder(column: $table.textEn, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  GeneratedColumn<int> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<int> get isHard =>
      $composableBuilder(column: $table.isHard, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MaterialSegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaterialSegmentsTable,
          MaterialSegment,
          $$MaterialSegmentsTableFilterComposer,
          $$MaterialSegmentsTableOrderingComposer,
          $$MaterialSegmentsTableAnnotationComposer,
          $$MaterialSegmentsTableCreateCompanionBuilder,
          $$MaterialSegmentsTableUpdateCompanionBuilder,
          (
            MaterialSegment,
            BaseReferences<
              _$AppDatabase,
              $MaterialSegmentsTable,
              MaterialSegment
            >,
          ),
          MaterialSegment,
          PrefetchHooks Function()
        > {
  $$MaterialSegmentsTableTableManager(
    _$AppDatabase db,
    $MaterialSegmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaterialSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaterialSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaterialSegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> materialId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> textEn = const Value.absent(),
                Value<int> startMs = const Value.absent(),
                Value<int> endMs = const Value.absent(),
                Value<int> wordCount = const Value.absent(),
                Value<int> isHard = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaterialSegmentsCompanion(
                id: id,
                materialId: materialId,
                seq: seq,
                textEn: textEn,
                startMs: startMs,
                endMs: endMs,
                wordCount: wordCount,
                isHard: isHard,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String materialId,
                required int seq,
                required String textEn,
                required int startMs,
                required int endMs,
                required int wordCount,
                required int isHard,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MaterialSegmentsCompanion.insert(
                id: id,
                materialId: materialId,
                seq: seq,
                textEn: textEn,
                startMs: startMs,
                endMs: endMs,
                wordCount: wordCount,
                isHard: isHard,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MaterialSegmentsTable, MaterialSegment>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MaterialSegmentsTable,
                    MaterialSegment
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MaterialSegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaterialSegmentsTable,
      MaterialSegment,
      $$MaterialSegmentsTableFilterComposer,
      $$MaterialSegmentsTableOrderingComposer,
      $$MaterialSegmentsTableAnnotationComposer,
      $$MaterialSegmentsTableCreateCompanionBuilder,
      $$MaterialSegmentsTableUpdateCompanionBuilder,
      (
        MaterialSegment,
        BaseReferences<_$AppDatabase, $MaterialSegmentsTable, MaterialSegment>,
      ),
      MaterialSegment,
      PrefetchHooks Function()
    >;
typedef $$DictationAttemptsTableCreateCompanionBuilder =
    DictationAttemptsCompanion Function({
      required String id,
      required String materialId,
      required String segmentId,
      required String userText,
      required double accuracy,
      required int passed,
      required String diffJson,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$DictationAttemptsTableUpdateCompanionBuilder =
    DictationAttemptsCompanion Function({
      Value<String> id,
      Value<String> materialId,
      Value<String> segmentId,
      Value<String> userText,
      Value<double> accuracy,
      Value<int> passed,
      Value<String> diffJson,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$DictationAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $DictationAttemptsTable> {
  $$DictationAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get materialId => $composableBuilder(
    column: $table.materialId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userText => $composableBuilder(
    column: $table.userText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get passed => $composableBuilder(
    column: $table.passed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get diffJson => $composableBuilder(
    column: $table.diffJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictationAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $DictationAttemptsTable> {
  $$DictationAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get materialId => $composableBuilder(
    column: $table.materialId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userText => $composableBuilder(
    column: $table.userText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get passed => $composableBuilder(
    column: $table.passed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get diffJson => $composableBuilder(
    column: $table.diffJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictationAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictationAttemptsTable> {
  $$DictationAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get materialId => $composableBuilder(
    column: $table.materialId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get segmentId =>
      $composableBuilder(column: $table.segmentId, builder: (column) => column);

  GeneratedColumn<String> get userText =>
      $composableBuilder(column: $table.userText, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<int> get passed =>
      $composableBuilder(column: $table.passed, builder: (column) => column);

  GeneratedColumn<String> get diffJson =>
      $composableBuilder(column: $table.diffJson, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DictationAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictationAttemptsTable,
          DictationAttempt,
          $$DictationAttemptsTableFilterComposer,
          $$DictationAttemptsTableOrderingComposer,
          $$DictationAttemptsTableAnnotationComposer,
          $$DictationAttemptsTableCreateCompanionBuilder,
          $$DictationAttemptsTableUpdateCompanionBuilder,
          (
            DictationAttempt,
            BaseReferences<
              _$AppDatabase,
              $DictationAttemptsTable,
              DictationAttempt
            >,
          ),
          DictationAttempt,
          PrefetchHooks Function()
        > {
  $$DictationAttemptsTableTableManager(
    _$AppDatabase db,
    $DictationAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictationAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictationAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictationAttemptsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> materialId = const Value.absent(),
                Value<String> segmentId = const Value.absent(),
                Value<String> userText = const Value.absent(),
                Value<double> accuracy = const Value.absent(),
                Value<int> passed = const Value.absent(),
                Value<String> diffJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DictationAttemptsCompanion(
                id: id,
                materialId: materialId,
                segmentId: segmentId,
                userText: userText,
                accuracy: accuracy,
                passed: passed,
                diffJson: diffJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String materialId,
                required String segmentId,
                required String userText,
                required double accuracy,
                required int passed,
                required String diffJson,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DictationAttemptsCompanion.insert(
                id: id,
                materialId: materialId,
                segmentId: segmentId,
                userText: userText,
                accuracy: accuracy,
                passed: passed,
                diffJson: diffJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DictationAttemptsTable, DictationAttempt>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DictationAttemptsTable,
                    DictationAttempt
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictationAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictationAttemptsTable,
      DictationAttempt,
      $$DictationAttemptsTableFilterComposer,
      $$DictationAttemptsTableOrderingComposer,
      $$DictationAttemptsTableAnnotationComposer,
      $$DictationAttemptsTableCreateCompanionBuilder,
      $$DictationAttemptsTableUpdateCompanionBuilder,
      (
        DictationAttempt,
        BaseReferences<
          _$AppDatabase,
          $DictationAttemptsTable,
          DictationAttempt
        >,
      ),
      DictationAttempt,
      PrefetchHooks Function()
    >;
typedef $$ReviewItemRowsTableCreateCompanionBuilder =
    ReviewItemRowsCompanion Function({
      required String id,
      required String sourceType,
      required String sourceId,
      required String textEn,
      Value<String?> textZh,
      required int dueAt,
      required int stage,
      required int streak,
      required int consolidated,
      Value<int?> lastPassed,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$ReviewItemRowsTableUpdateCompanionBuilder =
    ReviewItemRowsCompanion Function({
      Value<String> id,
      Value<String> sourceType,
      Value<String> sourceId,
      Value<String> textEn,
      Value<String?> textZh,
      Value<int> dueAt,
      Value<int> stage,
      Value<int> streak,
      Value<int> consolidated,
      Value<int?> lastPassed,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$ReviewItemRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewItemRowsTable> {
  $$ReviewItemRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textEn => $composableBuilder(
    column: $table.textEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textZh => $composableBuilder(
    column: $table.textZh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streak => $composableBuilder(
    column: $table.streak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consolidated => $composableBuilder(
    column: $table.consolidated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPassed => $composableBuilder(
    column: $table.lastPassed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewItemRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewItemRowsTable> {
  $$ReviewItemRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textEn => $composableBuilder(
    column: $table.textEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textZh => $composableBuilder(
    column: $table.textZh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streak => $composableBuilder(
    column: $table.streak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consolidated => $composableBuilder(
    column: $table.consolidated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPassed => $composableBuilder(
    column: $table.lastPassed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewItemRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewItemRowsTable> {
  $$ReviewItemRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get textEn =>
      $composableBuilder(column: $table.textEn, builder: (column) => column);

  GeneratedColumn<String> get textZh =>
      $composableBuilder(column: $table.textZh, builder: (column) => column);

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<int> get streak =>
      $composableBuilder(column: $table.streak, builder: (column) => column);

  GeneratedColumn<int> get consolidated => $composableBuilder(
    column: $table.consolidated,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPassed => $composableBuilder(
    column: $table.lastPassed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReviewItemRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewItemRowsTable,
          ReviewItemRow,
          $$ReviewItemRowsTableFilterComposer,
          $$ReviewItemRowsTableOrderingComposer,
          $$ReviewItemRowsTableAnnotationComposer,
          $$ReviewItemRowsTableCreateCompanionBuilder,
          $$ReviewItemRowsTableUpdateCompanionBuilder,
          (
            ReviewItemRow,
            BaseReferences<_$AppDatabase, $ReviewItemRowsTable, ReviewItemRow>,
          ),
          ReviewItemRow,
          PrefetchHooks Function()
        > {
  $$ReviewItemRowsTableTableManager(
    _$AppDatabase db,
    $ReviewItemRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewItemRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewItemRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewItemRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> textEn = const Value.absent(),
                Value<String?> textZh = const Value.absent(),
                Value<int> dueAt = const Value.absent(),
                Value<int> stage = const Value.absent(),
                Value<int> streak = const Value.absent(),
                Value<int> consolidated = const Value.absent(),
                Value<int?> lastPassed = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewItemRowsCompanion(
                id: id,
                sourceType: sourceType,
                sourceId: sourceId,
                textEn: textEn,
                textZh: textZh,
                dueAt: dueAt,
                stage: stage,
                streak: streak,
                consolidated: consolidated,
                lastPassed: lastPassed,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceType,
                required String sourceId,
                required String textEn,
                Value<String?> textZh = const Value.absent(),
                required int dueAt,
                required int stage,
                required int streak,
                required int consolidated,
                Value<int?> lastPassed = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ReviewItemRowsCompanion.insert(
                id: id,
                sourceType: sourceType,
                sourceId: sourceId,
                textEn: textEn,
                textZh: textZh,
                dueAt: dueAt,
                stage: stage,
                streak: streak,
                consolidated: consolidated,
                lastPassed: lastPassed,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewItemRowsTable, ReviewItemRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReviewItemRowsTable,
                    ReviewItemRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewItemRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewItemRowsTable,
      ReviewItemRow,
      $$ReviewItemRowsTableFilterComposer,
      $$ReviewItemRowsTableOrderingComposer,
      $$ReviewItemRowsTableAnnotationComposer,
      $$ReviewItemRowsTableCreateCompanionBuilder,
      $$ReviewItemRowsTableUpdateCompanionBuilder,
      (
        ReviewItemRow,
        BaseReferences<_$AppDatabase, $ReviewItemRowsTable, ReviewItemRow>,
      ),
      ReviewItemRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScenariosTableTableManager get scenarios =>
      $$ScenariosTableTableManager(_db, _db.scenarios);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$CorrectionsTableTableManager get corrections =>
      $$CorrectionsTableTableManager(_db, _db.corrections);
  $$PhrasesTableTableManager get phrases =>
      $$PhrasesTableTableManager(_db, _db.phrases);
  $$LlmProfilesTableTableManager get llmProfiles =>
      $$LlmProfilesTableTableManager(_db, _db.llmProfiles);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
  $$TtsCachesTableTableManager get ttsCaches =>
      $$TtsCachesTableTableManager(_db, _db.ttsCaches);
  $$AppMetasTableTableManager get appMetas =>
      $$AppMetasTableTableManager(_db, _db.appMetas);
  $$MaterialsTableTableManager get materials =>
      $$MaterialsTableTableManager(_db, _db.materials);
  $$MaterialSegmentsTableTableManager get materialSegments =>
      $$MaterialSegmentsTableTableManager(_db, _db.materialSegments);
  $$DictationAttemptsTableTableManager get dictationAttempts =>
      $$DictationAttemptsTableTableManager(_db, _db.dictationAttempts);
  $$ReviewItemRowsTableTableManager get reviewItemRows =>
      $$ReviewItemRowsTableTableManager(_db, _db.reviewItemRows);
}
