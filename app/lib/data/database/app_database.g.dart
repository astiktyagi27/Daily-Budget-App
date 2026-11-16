// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BudgetMonthsTable extends BudgetMonths
    with TableInfo<$BudgetMonthsTable, MonthRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetMonthsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate, int> startDay =
      GeneratedColumn<int>(
        'start_day',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      ).withConverter<CalendarDate>($BudgetMonthsTable.$converterstartDay);
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate, int> endDay =
      GeneratedColumn<int>(
        'end_day',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<CalendarDate>($BudgetMonthsTable.$converterendDay);
  static const VerificationMeta _salaryDayMeta = const VerificationMeta(
    'salaryDay',
  );
  @override
  late final GeneratedColumn<int> salaryDay = GeneratedColumn<int>(
    'salary_day',
    aliasedName,
    false,
    check: () => ComparableExpr(salaryDay).isBetweenValues(1, 31),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate, int>
  firstBudgetedDay = GeneratedColumn<int>(
    'first_budgeted_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<CalendarDate>($BudgetMonthsTable.$converterfirstBudgetedDay);
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<int> confirmedAt = GeneratedColumn<int>(
    'confirmed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startDay,
    endDay,
    salaryDay,
    firstBudgetedDay,
    confirmedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_months';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('salary_day')) {
      context.handle(
        _salaryDayMeta,
        salaryDay.isAcceptableOrUnknown(data['salary_day']!, _salaryDayMeta),
      );
    } else if (isInserting) {
      context.missing(_salaryDayMeta);
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_confirmedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MonthRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startDay: $BudgetMonthsTable.$converterstartDay.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}start_day'],
        )!,
      ),
      endDay: $BudgetMonthsTable.$converterendDay.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}end_day'],
        )!,
      ),
      salaryDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}salary_day'],
      )!,
      firstBudgetedDay: $BudgetMonthsTable.$converterfirstBudgetedDay.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}first_budgeted_day'],
        )!,
      ),
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}confirmed_at'],
      )!,
    );
  }

  @override
  $BudgetMonthsTable createAlias(String alias) {
    return $BudgetMonthsTable(attachedDatabase, alias);
  }

  static TypeConverter<CalendarDate, int> $converterstartDay =
      const CalendarDateConverter();
  static TypeConverter<CalendarDate, int> $converterendDay =
      const CalendarDateConverter();
  static TypeConverter<CalendarDate, int> $converterfirstBudgetedDay =
      const CalendarDateConverter();
}

class MonthRow extends DataClass implements Insertable<MonthRow> {
  final int id;
  final CalendarDate startDay;
  final CalendarDate endDay;
  final int salaryDay;
  final CalendarDate firstBudgetedDay;
  final int confirmedAt;
  const MonthRow({
    required this.id,
    required this.startDay,
    required this.endDay,
    required this.salaryDay,
    required this.firstBudgetedDay,
    required this.confirmedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['start_day'] = Variable<int>(
        $BudgetMonthsTable.$converterstartDay.toSql(startDay),
      );
    }
    {
      map['end_day'] = Variable<int>(
        $BudgetMonthsTable.$converterendDay.toSql(endDay),
      );
    }
    map['salary_day'] = Variable<int>(salaryDay);
    {
      map['first_budgeted_day'] = Variable<int>(
        $BudgetMonthsTable.$converterfirstBudgetedDay.toSql(firstBudgetedDay),
      );
    }
    map['confirmed_at'] = Variable<int>(confirmedAt);
    return map;
  }

  BudgetMonthsCompanion toCompanion(bool nullToAbsent) {
    return BudgetMonthsCompanion(
      id: Value(id),
      startDay: Value(startDay),
      endDay: Value(endDay),
      salaryDay: Value(salaryDay),
      firstBudgetedDay: Value(firstBudgetedDay),
      confirmedAt: Value(confirmedAt),
    );
  }

  factory MonthRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthRow(
      id: serializer.fromJson<int>(json['id']),
      startDay: serializer.fromJson<CalendarDate>(json['startDay']),
      endDay: serializer.fromJson<CalendarDate>(json['endDay']),
      salaryDay: serializer.fromJson<int>(json['salaryDay']),
      firstBudgetedDay: serializer.fromJson<CalendarDate>(
        json['firstBudgetedDay'],
      ),
      confirmedAt: serializer.fromJson<int>(json['confirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startDay': serializer.toJson<CalendarDate>(startDay),
      'endDay': serializer.toJson<CalendarDate>(endDay),
      'salaryDay': serializer.toJson<int>(salaryDay),
      'firstBudgetedDay': serializer.toJson<CalendarDate>(firstBudgetedDay),
      'confirmedAt': serializer.toJson<int>(confirmedAt),
    };
  }

  MonthRow copyWith({
    int? id,
    CalendarDate? startDay,
    CalendarDate? endDay,
    int? salaryDay,
    CalendarDate? firstBudgetedDay,
    int? confirmedAt,
  }) => MonthRow(
    id: id ?? this.id,
    startDay: startDay ?? this.startDay,
    endDay: endDay ?? this.endDay,
    salaryDay: salaryDay ?? this.salaryDay,
    firstBudgetedDay: firstBudgetedDay ?? this.firstBudgetedDay,
    confirmedAt: confirmedAt ?? this.confirmedAt,
  );
  MonthRow copyWithCompanion(BudgetMonthsCompanion data) {
    return MonthRow(
      id: data.id.present ? data.id.value : this.id,
      startDay: data.startDay.present ? data.startDay.value : this.startDay,
      endDay: data.endDay.present ? data.endDay.value : this.endDay,
      salaryDay: data.salaryDay.present ? data.salaryDay.value : this.salaryDay,
      firstBudgetedDay: data.firstBudgetedDay.present
          ? data.firstBudgetedDay.value
          : this.firstBudgetedDay,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthRow(')
          ..write('id: $id, ')
          ..write('startDay: $startDay, ')
          ..write('endDay: $endDay, ')
          ..write('salaryDay: $salaryDay, ')
          ..write('firstBudgetedDay: $firstBudgetedDay, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startDay,
    endDay,
    salaryDay,
    firstBudgetedDay,
    confirmedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthRow &&
          other.id == this.id &&
          other.startDay == this.startDay &&
          other.endDay == this.endDay &&
          other.salaryDay == this.salaryDay &&
          other.firstBudgetedDay == this.firstBudgetedDay &&
          other.confirmedAt == this.confirmedAt);
}

class BudgetMonthsCompanion extends UpdateCompanion<MonthRow> {
  final Value<int> id;
  final Value<CalendarDate> startDay;
  final Value<CalendarDate> endDay;
  final Value<int> salaryDay;
  final Value<CalendarDate> firstBudgetedDay;
  final Value<int> confirmedAt;
  const BudgetMonthsCompanion({
    this.id = const Value.absent(),
    this.startDay = const Value.absent(),
    this.endDay = const Value.absent(),
    this.salaryDay = const Value.absent(),
    this.firstBudgetedDay = const Value.absent(),
    this.confirmedAt = const Value.absent(),
  });
  BudgetMonthsCompanion.insert({
    this.id = const Value.absent(),
    required CalendarDate startDay,
    required CalendarDate endDay,
    required int salaryDay,
    required CalendarDate firstBudgetedDay,
    required int confirmedAt,
  }) : startDay = Value(startDay),
       endDay = Value(endDay),
       salaryDay = Value(salaryDay),
       firstBudgetedDay = Value(firstBudgetedDay),
       confirmedAt = Value(confirmedAt);
  static Insertable<MonthRow> custom({
    Expression<int>? id,
    Expression<int>? startDay,
    Expression<int>? endDay,
    Expression<int>? salaryDay,
    Expression<int>? firstBudgetedDay,
    Expression<int>? confirmedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startDay != null) 'start_day': startDay,
      if (endDay != null) 'end_day': endDay,
      if (salaryDay != null) 'salary_day': salaryDay,
      if (firstBudgetedDay != null) 'first_budgeted_day': firstBudgetedDay,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
    });
  }

  BudgetMonthsCompanion copyWith({
    Value<int>? id,
    Value<CalendarDate>? startDay,
    Value<CalendarDate>? endDay,
    Value<int>? salaryDay,
    Value<CalendarDate>? firstBudgetedDay,
    Value<int>? confirmedAt,
  }) {
    return BudgetMonthsCompanion(
      id: id ?? this.id,
      startDay: startDay ?? this.startDay,
      endDay: endDay ?? this.endDay,
      salaryDay: salaryDay ?? this.salaryDay,
      firstBudgetedDay: firstBudgetedDay ?? this.firstBudgetedDay,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startDay.present) {
      map['start_day'] = Variable<int>(
        $BudgetMonthsTable.$converterstartDay.toSql(startDay.value),
      );
    }
    if (endDay.present) {
      map['end_day'] = Variable<int>(
        $BudgetMonthsTable.$converterendDay.toSql(endDay.value),
      );
    }
    if (salaryDay.present) {
      map['salary_day'] = Variable<int>(salaryDay.value);
    }
    if (firstBudgetedDay.present) {
      map['first_budgeted_day'] = Variable<int>(
        $BudgetMonthsTable.$converterfirstBudgetedDay.toSql(
          firstBudgetedDay.value,
        ),
      );
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<int>(confirmedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetMonthsCompanion(')
          ..write('id: $id, ')
          ..write('startDay: $startDay, ')
          ..write('endDay: $endDay, ')
          ..write('salaryDay: $salaryDay, ')
          ..write('firstBudgetedDay: $firstBudgetedDay, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }
}

class $BudgetPeriodsTable extends BudgetPeriods
    with TableInfo<$BudgetPeriodsTable, PeriodRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetPeriodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _monthIdMeta = const VerificationMeta(
    'monthId',
  );
  @override
  late final GeneratedColumn<int> monthId = GeneratedColumn<int>(
    'month_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES budget_months (id) ON DELETE RESTRICT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate, int> startDay =
      GeneratedColumn<int>(
        'start_day',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<CalendarDate>($BudgetPeriodsTable.$converterstartDay);
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<int> changedAt = GeneratedColumn<int>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(['full', 'midMonthStart']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Paise?, int> salaryPaise =
      GeneratedColumn<int>(
        'salary_paise',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Paise?>($BudgetPeriodsTable.$convertersalaryPaisen);
  @override
  late final GeneratedColumnWithTypeConverter<Paise?, int> targetPaise =
      GeneratedColumn<int>(
        'target_paise',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Paise?>($BudgetPeriodsTable.$convertertargetPaisen);
  @override
  late final GeneratedColumnWithTypeConverter<Paise?, int> moneyLeftPaise =
      GeneratedColumn<int>(
        'money_left_paise',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Paise?>($BudgetPeriodsTable.$convertermoneyLeftPaisen);
  static const VerificationMeta _continuedWithShortfallMeta =
      const VerificationMeta('continuedWithShortfall');
  @override
  late final GeneratedColumn<bool> continuedWithShortfall =
      GeneratedColumn<bool>(
        'continued_with_shortfall',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("continued_with_shortfall" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  @override
  late final GeneratedColumnWithTypeConverter<Paise, int> shortfallPaise =
      GeneratedColumn<int>(
        'shortfall_paise',
        aliasedName,
        false,
        check: () => ComparableExpr(shortfallPaise).isBiggerOrEqualValue(0),
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<Paise>($BudgetPeriodsTable.$convertershortfallPaise);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    monthId,
    startDay,
    changedAt,
    kind,
    salaryPaise,
    targetPaise,
    moneyLeftPaise,
    continuedWithShortfall,
    shortfallPaise,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_periods';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeriodRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month_id')) {
      context.handle(
        _monthIdMeta,
        monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta),
      );
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('continued_with_shortfall')) {
      context.handle(
        _continuedWithShortfallMeta,
        continuedWithShortfall.isAcceptableOrUnknown(
          data['continued_with_shortfall']!,
          _continuedWithShortfallMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeriodRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeriodRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      monthId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month_id'],
      )!,
      startDay: $BudgetPeriodsTable.$converterstartDay.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}start_day'],
        )!,
      ),
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}changed_at'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      salaryPaise: $BudgetPeriodsTable.$convertersalaryPaisen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}salary_paise'],
        ),
      ),
      targetPaise: $BudgetPeriodsTable.$convertertargetPaisen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}target_paise'],
        ),
      ),
      moneyLeftPaise: $BudgetPeriodsTable.$convertermoneyLeftPaisen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}money_left_paise'],
        ),
      ),
      continuedWithShortfall: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}continued_with_shortfall'],
      )!,
      shortfallPaise: $BudgetPeriodsTable.$convertershortfallPaise.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}shortfall_paise'],
        )!,
      ),
    );
  }

  @override
  $BudgetPeriodsTable createAlias(String alias) {
    return $BudgetPeriodsTable(attachedDatabase, alias);
  }

  static TypeConverter<CalendarDate, int> $converterstartDay =
      const CalendarDateConverter();
  static TypeConverter<Paise, int> $convertersalaryPaise =
      const PaiseConverter();
  static TypeConverter<Paise?, int?> $convertersalaryPaisen =
      NullAwareTypeConverter.wrap($convertersalaryPaise);
  static TypeConverter<Paise, int> $convertertargetPaise =
      const PaiseConverter();
  static TypeConverter<Paise?, int?> $convertertargetPaisen =
      NullAwareTypeConverter.wrap($convertertargetPaise);
  static TypeConverter<Paise, int> $convertermoneyLeftPaise =
      const PaiseConverter();
  static TypeConverter<Paise?, int?> $convertermoneyLeftPaisen =
      NullAwareTypeConverter.wrap($convertermoneyLeftPaise);
  static TypeConverter<Paise, int> $convertershortfallPaise =
      const PaiseConverter();
}

class PeriodRow extends DataClass implements Insertable<PeriodRow> {
  final int id;
  final int monthId;
  final CalendarDate startDay;
  final int changedAt;

  /// `full` or `midMonthStart`.
  final String kind;
  final Paise? salaryPaise;
  final Paise? targetPaise;
  final Paise? moneyLeftPaise;
  final bool continuedWithShortfall;
  final Paise shortfallPaise;
  const PeriodRow({
    required this.id,
    required this.monthId,
    required this.startDay,
    required this.changedAt,
    required this.kind,
    this.salaryPaise,
    this.targetPaise,
    this.moneyLeftPaise,
    required this.continuedWithShortfall,
    required this.shortfallPaise,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month_id'] = Variable<int>(monthId);
    {
      map['start_day'] = Variable<int>(
        $BudgetPeriodsTable.$converterstartDay.toSql(startDay),
      );
    }
    map['changed_at'] = Variable<int>(changedAt);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || salaryPaise != null) {
      map['salary_paise'] = Variable<int>(
        $BudgetPeriodsTable.$convertersalaryPaisen.toSql(salaryPaise),
      );
    }
    if (!nullToAbsent || targetPaise != null) {
      map['target_paise'] = Variable<int>(
        $BudgetPeriodsTable.$convertertargetPaisen.toSql(targetPaise),
      );
    }
    if (!nullToAbsent || moneyLeftPaise != null) {
      map['money_left_paise'] = Variable<int>(
        $BudgetPeriodsTable.$convertermoneyLeftPaisen.toSql(moneyLeftPaise),
      );
    }
    map['continued_with_shortfall'] = Variable<bool>(continuedWithShortfall);
    {
      map['shortfall_paise'] = Variable<int>(
        $BudgetPeriodsTable.$convertershortfallPaise.toSql(shortfallPaise),
      );
    }
    return map;
  }

  BudgetPeriodsCompanion toCompanion(bool nullToAbsent) {
    return BudgetPeriodsCompanion(
      id: Value(id),
      monthId: Value(monthId),
      startDay: Value(startDay),
      changedAt: Value(changedAt),
      kind: Value(kind),
      salaryPaise: salaryPaise == null && nullToAbsent
          ? const Value.absent()
          : Value(salaryPaise),
      targetPaise: targetPaise == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPaise),
      moneyLeftPaise: moneyLeftPaise == null && nullToAbsent
          ? const Value.absent()
          : Value(moneyLeftPaise),
      continuedWithShortfall: Value(continuedWithShortfall),
      shortfallPaise: Value(shortfallPaise),
    );
  }

  factory PeriodRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodRow(
      id: serializer.fromJson<int>(json['id']),
      monthId: serializer.fromJson<int>(json['monthId']),
      startDay: serializer.fromJson<CalendarDate>(json['startDay']),
      changedAt: serializer.fromJson<int>(json['changedAt']),
      kind: serializer.fromJson<String>(json['kind']),
      salaryPaise: serializer.fromJson<Paise?>(json['salaryPaise']),
      targetPaise: serializer.fromJson<Paise?>(json['targetPaise']),
      moneyLeftPaise: serializer.fromJson<Paise?>(json['moneyLeftPaise']),
      continuedWithShortfall: serializer.fromJson<bool>(
        json['continuedWithShortfall'],
      ),
      shortfallPaise: serializer.fromJson<Paise>(json['shortfallPaise']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monthId': serializer.toJson<int>(monthId),
      'startDay': serializer.toJson<CalendarDate>(startDay),
      'changedAt': serializer.toJson<int>(changedAt),
      'kind': serializer.toJson<String>(kind),
      'salaryPaise': serializer.toJson<Paise?>(salaryPaise),
      'targetPaise': serializer.toJson<Paise?>(targetPaise),
      'moneyLeftPaise': serializer.toJson<Paise?>(moneyLeftPaise),
      'continuedWithShortfall': serializer.toJson<bool>(continuedWithShortfall),
      'shortfallPaise': serializer.toJson<Paise>(shortfallPaise),
    };
  }

  PeriodRow copyWith({
    int? id,
    int? monthId,
    CalendarDate? startDay,
    int? changedAt,
    String? kind,
    Value<Paise?> salaryPaise = const Value.absent(),
    Value<Paise?> targetPaise = const Value.absent(),
    Value<Paise?> moneyLeftPaise = const Value.absent(),
    bool? continuedWithShortfall,
    Paise? shortfallPaise,
  }) => PeriodRow(
    id: id ?? this.id,
    monthId: monthId ?? this.monthId,
    startDay: startDay ?? this.startDay,
    changedAt: changedAt ?? this.changedAt,
    kind: kind ?? this.kind,
    salaryPaise: salaryPaise.present ? salaryPaise.value : this.salaryPaise,
    targetPaise: targetPaise.present ? targetPaise.value : this.targetPaise,
    moneyLeftPaise: moneyLeftPaise.present
        ? moneyLeftPaise.value
        : this.moneyLeftPaise,
    continuedWithShortfall:
        continuedWithShortfall ?? this.continuedWithShortfall,
    shortfallPaise: shortfallPaise ?? this.shortfallPaise,
  );
  PeriodRow copyWithCompanion(BudgetPeriodsCompanion data) {
    return PeriodRow(
      id: data.id.present ? data.id.value : this.id,
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      startDay: data.startDay.present ? data.startDay.value : this.startDay,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      salaryPaise: data.salaryPaise.present
          ? data.salaryPaise.value
          : this.salaryPaise,
      targetPaise: data.targetPaise.present
          ? data.targetPaise.value
          : this.targetPaise,
      moneyLeftPaise: data.moneyLeftPaise.present
          ? data.moneyLeftPaise.value
          : this.moneyLeftPaise,
      continuedWithShortfall: data.continuedWithShortfall.present
          ? data.continuedWithShortfall.value
          : this.continuedWithShortfall,
      shortfallPaise: data.shortfallPaise.present
          ? data.shortfallPaise.value
          : this.shortfallPaise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodRow(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('startDay: $startDay, ')
          ..write('changedAt: $changedAt, ')
          ..write('kind: $kind, ')
          ..write('salaryPaise: $salaryPaise, ')
          ..write('targetPaise: $targetPaise, ')
          ..write('moneyLeftPaise: $moneyLeftPaise, ')
          ..write('continuedWithShortfall: $continuedWithShortfall, ')
          ..write('shortfallPaise: $shortfallPaise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    monthId,
    startDay,
    changedAt,
    kind,
    salaryPaise,
    targetPaise,
    moneyLeftPaise,
    continuedWithShortfall,
    shortfallPaise,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodRow &&
          other.id == this.id &&
          other.monthId == this.monthId &&
          other.startDay == this.startDay &&
          other.changedAt == this.changedAt &&
          other.kind == this.kind &&
          other.salaryPaise == this.salaryPaise &&
          other.targetPaise == this.targetPaise &&
          other.moneyLeftPaise == this.moneyLeftPaise &&
          other.continuedWithShortfall == this.continuedWithShortfall &&
          other.shortfallPaise == this.shortfallPaise);
}

class BudgetPeriodsCompanion extends UpdateCompanion<PeriodRow> {
  final Value<int> id;
  final Value<int> monthId;
  final Value<CalendarDate> startDay;
  final Value<int> changedAt;
  final Value<String> kind;
  final Value<Paise?> salaryPaise;
  final Value<Paise?> targetPaise;
  final Value<Paise?> moneyLeftPaise;
  final Value<bool> continuedWithShortfall;
  final Value<Paise> shortfallPaise;
  const BudgetPeriodsCompanion({
    this.id = const Value.absent(),
    this.monthId = const Value.absent(),
    this.startDay = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.salaryPaise = const Value.absent(),
    this.targetPaise = const Value.absent(),
    this.moneyLeftPaise = const Value.absent(),
    this.continuedWithShortfall = const Value.absent(),
    this.shortfallPaise = const Value.absent(),
  });
  BudgetPeriodsCompanion.insert({
    this.id = const Value.absent(),
    required int monthId,
    required CalendarDate startDay,
    required int changedAt,
    required String kind,
    this.salaryPaise = const Value.absent(),
    this.targetPaise = const Value.absent(),
    this.moneyLeftPaise = const Value.absent(),
    this.continuedWithShortfall = const Value.absent(),
    this.shortfallPaise = const Value.absent(),
  }) : monthId = Value(monthId),
       startDay = Value(startDay),
       changedAt = Value(changedAt),
       kind = Value(kind);
  static Insertable<PeriodRow> custom({
    Expression<int>? id,
    Expression<int>? monthId,
    Expression<int>? startDay,
    Expression<int>? changedAt,
    Expression<String>? kind,
    Expression<int>? salaryPaise,
    Expression<int>? targetPaise,
    Expression<int>? moneyLeftPaise,
    Expression<bool>? continuedWithShortfall,
    Expression<int>? shortfallPaise,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monthId != null) 'month_id': monthId,
      if (startDay != null) 'start_day': startDay,
      if (changedAt != null) 'changed_at': changedAt,
      if (kind != null) 'kind': kind,
      if (salaryPaise != null) 'salary_paise': salaryPaise,
      if (targetPaise != null) 'target_paise': targetPaise,
      if (moneyLeftPaise != null) 'money_left_paise': moneyLeftPaise,
      if (continuedWithShortfall != null)
        'continued_with_shortfall': continuedWithShortfall,
      if (shortfallPaise != null) 'shortfall_paise': shortfallPaise,
    });
  }

  BudgetPeriodsCompanion copyWith({
    Value<int>? id,
    Value<int>? monthId,
    Value<CalendarDate>? startDay,
    Value<int>? changedAt,
    Value<String>? kind,
    Value<Paise?>? salaryPaise,
    Value<Paise?>? targetPaise,
    Value<Paise?>? moneyLeftPaise,
    Value<bool>? continuedWithShortfall,
    Value<Paise>? shortfallPaise,
  }) {
    return BudgetPeriodsCompanion(
      id: id ?? this.id,
      monthId: monthId ?? this.monthId,
      startDay: startDay ?? this.startDay,
      changedAt: changedAt ?? this.changedAt,
      kind: kind ?? this.kind,
      salaryPaise: salaryPaise ?? this.salaryPaise,
      targetPaise: targetPaise ?? this.targetPaise,
      moneyLeftPaise: moneyLeftPaise ?? this.moneyLeftPaise,
      continuedWithShortfall:
          continuedWithShortfall ?? this.continuedWithShortfall,
      shortfallPaise: shortfallPaise ?? this.shortfallPaise,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monthId.present) {
      map['month_id'] = Variable<int>(monthId.value);
    }
    if (startDay.present) {
      map['start_day'] = Variable<int>(
        $BudgetPeriodsTable.$converterstartDay.toSql(startDay.value),
      );
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<int>(changedAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (salaryPaise.present) {
      map['salary_paise'] = Variable<int>(
        $BudgetPeriodsTable.$convertersalaryPaisen.toSql(salaryPaise.value),
      );
    }
    if (targetPaise.present) {
      map['target_paise'] = Variable<int>(
        $BudgetPeriodsTable.$convertertargetPaisen.toSql(targetPaise.value),
      );
    }
    if (moneyLeftPaise.present) {
      map['money_left_paise'] = Variable<int>(
        $BudgetPeriodsTable.$convertermoneyLeftPaisen.toSql(
          moneyLeftPaise.value,
        ),
      );
    }
    if (continuedWithShortfall.present) {
      map['continued_with_shortfall'] = Variable<bool>(
        continuedWithShortfall.value,
      );
    }
    if (shortfallPaise.present) {
      map['shortfall_paise'] = Variable<int>(
        $BudgetPeriodsTable.$convertershortfallPaise.toSql(
          shortfallPaise.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetPeriodsCompanion(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('startDay: $startDay, ')
          ..write('changedAt: $changedAt, ')
          ..write('kind: $kind, ')
          ..write('salaryPaise: $salaryPaise, ')
          ..write('targetPaise: $targetPaise, ')
          ..write('moneyLeftPaise: $moneyLeftPaise, ')
          ..write('continuedWithShortfall: $continuedWithShortfall, ')
          ..write('shortfallPaise: $shortfallPaise')
          ..write(')'))
        .toString();
  }
}

class $PeriodFixedCostsTable extends PeriodFixedCosts
    with TableInfo<$PeriodFixedCostsTable, FixedCostRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodFixedCostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _periodIdMeta = const VerificationMeta(
    'periodId',
  );
  @override
  late final GeneratedColumn<int> periodId = GeneratedColumn<int>(
    'period_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES budget_periods (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    check: () => ComparableExpr(name.length).isBetweenValues(1, 160),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Paise, int> amountPaise =
      GeneratedColumn<int>(
        'amount_paise',
        aliasedName,
        false,
        check: () => ComparableExpr(amountPaise).isBiggerOrEqualValue(0),
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Paise>($PeriodFixedCostsTable.$converteramountPaise);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    periodId,
    position,
    name,
    amountPaise,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'period_fixed_costs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FixedCostRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('period_id')) {
      context.handle(
        _periodIdMeta,
        periodId.isAcceptableOrUnknown(data['period_id']!, _periodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_periodIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FixedCostRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FixedCostRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      periodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amountPaise: $PeriodFixedCostsTable.$converteramountPaise.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}amount_paise'],
        )!,
      ),
    );
  }

  @override
  $PeriodFixedCostsTable createAlias(String alias) {
    return $PeriodFixedCostsTable(attachedDatabase, alias);
  }

  static TypeConverter<Paise, int> $converteramountPaise =
      const PaiseConverter();
}

class FixedCostRow extends DataClass implements Insertable<FixedCostRow> {
  final int id;
  final int periodId;
  final int position;

  /// The screen limits a name to 40 characters as the user sees them; the
  /// CHECK counts code points, so 160 is only a backstop.
  final String name;
  final Paise amountPaise;
  const FixedCostRow({
    required this.id,
    required this.periodId,
    required this.position,
    required this.name,
    required this.amountPaise,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['period_id'] = Variable<int>(periodId);
    map['position'] = Variable<int>(position);
    map['name'] = Variable<String>(name);
    {
      map['amount_paise'] = Variable<int>(
        $PeriodFixedCostsTable.$converteramountPaise.toSql(amountPaise),
      );
    }
    return map;
  }

  PeriodFixedCostsCompanion toCompanion(bool nullToAbsent) {
    return PeriodFixedCostsCompanion(
      id: Value(id),
      periodId: Value(periodId),
      position: Value(position),
      name: Value(name),
      amountPaise: Value(amountPaise),
    );
  }

  factory FixedCostRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FixedCostRow(
      id: serializer.fromJson<int>(json['id']),
      periodId: serializer.fromJson<int>(json['periodId']),
      position: serializer.fromJson<int>(json['position']),
      name: serializer.fromJson<String>(json['name']),
      amountPaise: serializer.fromJson<Paise>(json['amountPaise']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'periodId': serializer.toJson<int>(periodId),
      'position': serializer.toJson<int>(position),
      'name': serializer.toJson<String>(name),
      'amountPaise': serializer.toJson<Paise>(amountPaise),
    };
  }

  FixedCostRow copyWith({
    int? id,
    int? periodId,
    int? position,
    String? name,
    Paise? amountPaise,
  }) => FixedCostRow(
    id: id ?? this.id,
    periodId: periodId ?? this.periodId,
    position: position ?? this.position,
    name: name ?? this.name,
    amountPaise: amountPaise ?? this.amountPaise,
  );
  FixedCostRow copyWithCompanion(PeriodFixedCostsCompanion data) {
    return FixedCostRow(
      id: data.id.present ? data.id.value : this.id,
      periodId: data.periodId.present ? data.periodId.value : this.periodId,
      position: data.position.present ? data.position.value : this.position,
      name: data.name.present ? data.name.value : this.name,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FixedCostRow(')
          ..write('id: $id, ')
          ..write('periodId: $periodId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('amountPaise: $amountPaise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, periodId, position, name, amountPaise);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FixedCostRow &&
          other.id == this.id &&
          other.periodId == this.periodId &&
          other.position == this.position &&
          other.name == this.name &&
          other.amountPaise == this.amountPaise);
}

class PeriodFixedCostsCompanion extends UpdateCompanion<FixedCostRow> {
  final Value<int> id;
  final Value<int> periodId;
  final Value<int> position;
  final Value<String> name;
  final Value<Paise> amountPaise;
  const PeriodFixedCostsCompanion({
    this.id = const Value.absent(),
    this.periodId = const Value.absent(),
    this.position = const Value.absent(),
    this.name = const Value.absent(),
    this.amountPaise = const Value.absent(),
  });
  PeriodFixedCostsCompanion.insert({
    this.id = const Value.absent(),
    required int periodId,
    required int position,
    required String name,
    required Paise amountPaise,
  }) : periodId = Value(periodId),
       position = Value(position),
       name = Value(name),
       amountPaise = Value(amountPaise);
  static Insertable<FixedCostRow> custom({
    Expression<int>? id,
    Expression<int>? periodId,
    Expression<int>? position,
    Expression<String>? name,
    Expression<int>? amountPaise,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (periodId != null) 'period_id': periodId,
      if (position != null) 'position': position,
      if (name != null) 'name': name,
      if (amountPaise != null) 'amount_paise': amountPaise,
    });
  }

  PeriodFixedCostsCompanion copyWith({
    Value<int>? id,
    Value<int>? periodId,
    Value<int>? position,
    Value<String>? name,
    Value<Paise>? amountPaise,
  }) {
    return PeriodFixedCostsCompanion(
      id: id ?? this.id,
      periodId: periodId ?? this.periodId,
      position: position ?? this.position,
      name: name ?? this.name,
      amountPaise: amountPaise ?? this.amountPaise,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (periodId.present) {
      map['period_id'] = Variable<int>(periodId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(
        $PeriodFixedCostsTable.$converteramountPaise.toSql(amountPaise.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodFixedCostsCompanion(')
          ..write('id: $id, ')
          ..write('periodId: $periodId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('amountPaise: $amountPaise')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _monthIdMeta = const VerificationMeta(
    'monthId',
  );
  @override
  late final GeneratedColumn<int> monthId = GeneratedColumn<int>(
    'month_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES budget_months (id) ON DELETE RESTRICT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate, int> day =
      GeneratedColumn<int>(
        'day',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<CalendarDate>($TransactionsTable.$converterday);
  @override
  late final GeneratedColumnWithTypeConverter<Paise, int> amountPaise =
      GeneratedColumn<int>(
        'amount_paise',
        aliasedName,
        false,
        check: () => ComparableExpr(amountPaise).isBiggerThanValue(0),
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Paise>($TransactionsTable.$converteramountPaise);
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    check: () => direction.isIn(['spend', 'money_in']),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('spend'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    check: () => ComparableExpr(note.length).isSmallerOrEqualValue(400),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    check: () => source.isIn(['manual']),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    monthId,
    day,
    amountPaise,
    direction,
    note,
    source,
    category,
    createdAt,
    editedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month_id')) {
      context.handle(
        _monthIdMeta,
        monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta),
      );
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
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
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_editedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      monthId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month_id'],
      )!,
      day: $TransactionsTable.$converterday.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}day'],
        )!,
      ),
      amountPaise: $TransactionsTable.$converteramountPaise.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}amount_paise'],
        )!,
      ),
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static TypeConverter<CalendarDate, int> $converterday =
      const CalendarDateConverter();
  static TypeConverter<Paise, int> $converteramountPaise =
      const PaiseConverter();
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int id;
  final int monthId;
  final CalendarDate day;
  final Paise amountPaise;

  /// `spend` or `money_in` (D-047).
  final String direction;

  /// The note is limited to 100 characters by the screen. The CHECK counts
  /// code points, so 400 is only a backstop.
  final String note;

  /// `manual` now; Phase 4 adds `sms` by migration.
  final String source;
  final String? category;
  final int createdAt;
  final int editedAt;
  const TransactionRow({
    required this.id,
    required this.monthId,
    required this.day,
    required this.amountPaise,
    required this.direction,
    required this.note,
    required this.source,
    this.category,
    required this.createdAt,
    required this.editedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month_id'] = Variable<int>(monthId);
    {
      map['day'] = Variable<int>($TransactionsTable.$converterday.toSql(day));
    }
    {
      map['amount_paise'] = Variable<int>(
        $TransactionsTable.$converteramountPaise.toSql(amountPaise),
      );
    }
    map['direction'] = Variable<String>(direction);
    map['note'] = Variable<String>(note);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['edited_at'] = Variable<int>(editedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      monthId: Value(monthId),
      day: Value(day),
      amountPaise: Value(amountPaise),
      direction: Value(direction),
      note: Value(note),
      source: Value(source),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      createdAt: Value(createdAt),
      editedAt: Value(editedAt),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<int>(json['id']),
      monthId: serializer.fromJson<int>(json['monthId']),
      day: serializer.fromJson<CalendarDate>(json['day']),
      amountPaise: serializer.fromJson<Paise>(json['amountPaise']),
      direction: serializer.fromJson<String>(json['direction']),
      note: serializer.fromJson<String>(json['note']),
      source: serializer.fromJson<String>(json['source']),
      category: serializer.fromJson<String?>(json['category']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      editedAt: serializer.fromJson<int>(json['editedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monthId': serializer.toJson<int>(monthId),
      'day': serializer.toJson<CalendarDate>(day),
      'amountPaise': serializer.toJson<Paise>(amountPaise),
      'direction': serializer.toJson<String>(direction),
      'note': serializer.toJson<String>(note),
      'source': serializer.toJson<String>(source),
      'category': serializer.toJson<String?>(category),
      'createdAt': serializer.toJson<int>(createdAt),
      'editedAt': serializer.toJson<int>(editedAt),
    };
  }

  TransactionRow copyWith({
    int? id,
    int? monthId,
    CalendarDate? day,
    Paise? amountPaise,
    String? direction,
    String? note,
    String? source,
    Value<String?> category = const Value.absent(),
    int? createdAt,
    int? editedAt,
  }) => TransactionRow(
    id: id ?? this.id,
    monthId: monthId ?? this.monthId,
    day: day ?? this.day,
    amountPaise: amountPaise ?? this.amountPaise,
    direction: direction ?? this.direction,
    note: note ?? this.note,
    source: source ?? this.source,
    category: category.present ? category.value : this.category,
    createdAt: createdAt ?? this.createdAt,
    editedAt: editedAt ?? this.editedAt,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      day: data.day.present ? data.day.value : this.day,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      direction: data.direction.present ? data.direction.value : this.direction,
      note: data.note.present ? data.note.value : this.note,
      source: data.source.present ? data.source.value : this.source,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('day: $day, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('direction: $direction, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    monthId,
    day,
    amountPaise,
    direction,
    note,
    source,
    category,
    createdAt,
    editedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.monthId == this.monthId &&
          other.day == this.day &&
          other.amountPaise == this.amountPaise &&
          other.direction == this.direction &&
          other.note == this.note &&
          other.source == this.source &&
          other.category == this.category &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> id;
  final Value<int> monthId;
  final Value<CalendarDate> day;
  final Value<Paise> amountPaise;
  final Value<String> direction;
  final Value<String> note;
  final Value<String> source;
  final Value<String?> category;
  final Value<int> createdAt;
  final Value<int> editedAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.monthId = const Value.absent(),
    this.day = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.direction = const Value.absent(),
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int monthId,
    required CalendarDate day,
    required Paise amountPaise,
    this.direction = const Value.absent(),
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.category = const Value.absent(),
    required int createdAt,
    required int editedAt,
  }) : monthId = Value(monthId),
       day = Value(day),
       amountPaise = Value(amountPaise),
       createdAt = Value(createdAt),
       editedAt = Value(editedAt);
  static Insertable<TransactionRow> custom({
    Expression<int>? id,
    Expression<int>? monthId,
    Expression<int>? day,
    Expression<int>? amountPaise,
    Expression<String>? direction,
    Expression<String>? note,
    Expression<String>? source,
    Expression<String>? category,
    Expression<int>? createdAt,
    Expression<int>? editedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monthId != null) 'month_id': monthId,
      if (day != null) 'day': day,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (direction != null) 'direction': direction,
      if (note != null) 'note': note,
      if (source != null) 'source': source,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? monthId,
    Value<CalendarDate>? day,
    Value<Paise>? amountPaise,
    Value<String>? direction,
    Value<String>? note,
    Value<String>? source,
    Value<String?>? category,
    Value<int>? createdAt,
    Value<int>? editedAt,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      monthId: monthId ?? this.monthId,
      day: day ?? this.day,
      amountPaise: amountPaise ?? this.amountPaise,
      direction: direction ?? this.direction,
      note: note ?? this.note,
      source: source ?? this.source,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monthId.present) {
      map['month_id'] = Variable<int>(monthId.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(
        $TransactionsTable.$converterday.toSql(day.value),
      );
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(
        $TransactionsTable.$converteramountPaise.toSql(amountPaise.value),
      );
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('day: $day, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('direction: $direction, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }
}

class $SavingsMovesTable extends SavingsMoves
    with TableInfo<$SavingsMovesTable, SavingsMoveRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsMovesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _monthIdMeta = const VerificationMeta(
    'monthId',
  );
  @override
  late final GeneratedColumn<int> monthId = GeneratedColumn<int>(
    'month_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES budget_months (id) ON DELETE RESTRICT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate, int> coveredDay =
      GeneratedColumn<int>(
        'covered_day',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<CalendarDate>($SavingsMovesTable.$convertercoveredDay);
  @override
  late final GeneratedColumnWithTypeConverter<Paise, int> amountPaise =
      GeneratedColumn<int>(
        'amount_paise',
        aliasedName,
        false,
        check: () => ComparableExpr(amountPaise).isBiggerOrEqualValue(0),
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Paise>($SavingsMovesTable.$converteramountPaise);
  static const VerificationMeta _madeAtMeta = const VerificationMeta('madeAt');
  @override
  late final GeneratedColumn<int> madeAt = GeneratedColumn<int>(
    'made_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    monthId,
    coveredDay,
    amountPaise,
    madeAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_moves';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsMoveRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month_id')) {
      context.handle(
        _monthIdMeta,
        monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta),
      );
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('made_at')) {
      context.handle(
        _madeAtMeta,
        madeAt.isAcceptableOrUnknown(data['made_at']!, _madeAtMeta),
      );
    } else if (isInserting) {
      context.missing(_madeAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsMoveRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsMoveRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      monthId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month_id'],
      )!,
      coveredDay: $SavingsMovesTable.$convertercoveredDay.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}covered_day'],
        )!,
      ),
      amountPaise: $SavingsMovesTable.$converteramountPaise.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}amount_paise'],
        )!,
      ),
      madeAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}made_at'],
      )!,
    );
  }

  @override
  $SavingsMovesTable createAlias(String alias) {
    return $SavingsMovesTable(attachedDatabase, alias);
  }

  static TypeConverter<CalendarDate, int> $convertercoveredDay =
      const CalendarDateConverter();
  static TypeConverter<Paise, int> $converteramountPaise =
      const PaiseConverter();
}

class SavingsMoveRow extends DataClass implements Insertable<SavingsMoveRow> {
  final int id;
  final int monthId;
  final CalendarDate coveredDay;
  final Paise amountPaise;
  final int madeAt;
  const SavingsMoveRow({
    required this.id,
    required this.monthId,
    required this.coveredDay,
    required this.amountPaise,
    required this.madeAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month_id'] = Variable<int>(monthId);
    {
      map['covered_day'] = Variable<int>(
        $SavingsMovesTable.$convertercoveredDay.toSql(coveredDay),
      );
    }
    {
      map['amount_paise'] = Variable<int>(
        $SavingsMovesTable.$converteramountPaise.toSql(amountPaise),
      );
    }
    map['made_at'] = Variable<int>(madeAt);
    return map;
  }

  SavingsMovesCompanion toCompanion(bool nullToAbsent) {
    return SavingsMovesCompanion(
      id: Value(id),
      monthId: Value(monthId),
      coveredDay: Value(coveredDay),
      amountPaise: Value(amountPaise),
      madeAt: Value(madeAt),
    );
  }

  factory SavingsMoveRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsMoveRow(
      id: serializer.fromJson<int>(json['id']),
      monthId: serializer.fromJson<int>(json['monthId']),
      coveredDay: serializer.fromJson<CalendarDate>(json['coveredDay']),
      amountPaise: serializer.fromJson<Paise>(json['amountPaise']),
      madeAt: serializer.fromJson<int>(json['madeAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monthId': serializer.toJson<int>(monthId),
      'coveredDay': serializer.toJson<CalendarDate>(coveredDay),
      'amountPaise': serializer.toJson<Paise>(amountPaise),
      'madeAt': serializer.toJson<int>(madeAt),
    };
  }

  SavingsMoveRow copyWith({
    int? id,
    int? monthId,
    CalendarDate? coveredDay,
    Paise? amountPaise,
    int? madeAt,
  }) => SavingsMoveRow(
    id: id ?? this.id,
    monthId: monthId ?? this.monthId,
    coveredDay: coveredDay ?? this.coveredDay,
    amountPaise: amountPaise ?? this.amountPaise,
    madeAt: madeAt ?? this.madeAt,
  );
  SavingsMoveRow copyWithCompanion(SavingsMovesCompanion data) {
    return SavingsMoveRow(
      id: data.id.present ? data.id.value : this.id,
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      coveredDay: data.coveredDay.present
          ? data.coveredDay.value
          : this.coveredDay,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      madeAt: data.madeAt.present ? data.madeAt.value : this.madeAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsMoveRow(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('coveredDay: $coveredDay, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('madeAt: $madeAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, monthId, coveredDay, amountPaise, madeAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsMoveRow &&
          other.id == this.id &&
          other.monthId == this.monthId &&
          other.coveredDay == this.coveredDay &&
          other.amountPaise == this.amountPaise &&
          other.madeAt == this.madeAt);
}

class SavingsMovesCompanion extends UpdateCompanion<SavingsMoveRow> {
  final Value<int> id;
  final Value<int> monthId;
  final Value<CalendarDate> coveredDay;
  final Value<Paise> amountPaise;
  final Value<int> madeAt;
  const SavingsMovesCompanion({
    this.id = const Value.absent(),
    this.monthId = const Value.absent(),
    this.coveredDay = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.madeAt = const Value.absent(),
  });
  SavingsMovesCompanion.insert({
    this.id = const Value.absent(),
    required int monthId,
    required CalendarDate coveredDay,
    required Paise amountPaise,
    required int madeAt,
  }) : monthId = Value(monthId),
       coveredDay = Value(coveredDay),
       amountPaise = Value(amountPaise),
       madeAt = Value(madeAt);
  static Insertable<SavingsMoveRow> custom({
    Expression<int>? id,
    Expression<int>? monthId,
    Expression<int>? coveredDay,
    Expression<int>? amountPaise,
    Expression<int>? madeAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monthId != null) 'month_id': monthId,
      if (coveredDay != null) 'covered_day': coveredDay,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (madeAt != null) 'made_at': madeAt,
    });
  }

  SavingsMovesCompanion copyWith({
    Value<int>? id,
    Value<int>? monthId,
    Value<CalendarDate>? coveredDay,
    Value<Paise>? amountPaise,
    Value<int>? madeAt,
  }) {
    return SavingsMovesCompanion(
      id: id ?? this.id,
      monthId: monthId ?? this.monthId,
      coveredDay: coveredDay ?? this.coveredDay,
      amountPaise: amountPaise ?? this.amountPaise,
      madeAt: madeAt ?? this.madeAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monthId.present) {
      map['month_id'] = Variable<int>(monthId.value);
    }
    if (coveredDay.present) {
      map['covered_day'] = Variable<int>(
        $SavingsMovesTable.$convertercoveredDay.toSql(coveredDay.value),
      );
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(
        $SavingsMovesTable.$converteramountPaise.toSql(amountPaise.value),
      );
    }
    if (madeAt.present) {
      map['made_at'] = Variable<int>(madeAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsMovesCompanion(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('coveredDay: $coveredDay, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('madeAt: $madeAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BudgetMonthsTable budgetMonths = $BudgetMonthsTable(this);
  late final $BudgetPeriodsTable budgetPeriods = $BudgetPeriodsTable(this);
  late final Trigger budgetPeriodsNoUpdate = Trigger(
    'CREATE TRIGGER budget_periods_no_update BEFORE UPDATE ON budget_periods BEGIN SELECT RAISE (ABORT, \'append-only\');END',
    'budget_periods_no_update',
  );
  late final Trigger budgetPeriodsNoDelete = Trigger(
    'CREATE TRIGGER budget_periods_no_delete BEFORE DELETE ON budget_periods BEGIN SELECT RAISE (ABORT, \'append-only\');END',
    'budget_periods_no_delete',
  );
  late final $PeriodFixedCostsTable periodFixedCosts = $PeriodFixedCostsTable(
    this,
  );
  late final Trigger periodFixedCostsNoUpdate = Trigger(
    'CREATE TRIGGER period_fixed_costs_no_update BEFORE UPDATE ON period_fixed_costs BEGIN SELECT RAISE (ABORT, \'append-only\');END',
    'period_fixed_costs_no_update',
  );
  late final Trigger periodFixedCostsNoDelete = Trigger(
    'CREATE TRIGGER period_fixed_costs_no_delete BEFORE DELETE ON period_fixed_costs BEGIN SELECT RAISE (ABORT, \'append-only\');END',
    'period_fixed_costs_no_delete',
  );
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $SavingsMovesTable savingsMoves = $SavingsMovesTable(this);
  late final Index idxPeriodsMonth = Index(
    'idx_periods_month',
    'CREATE INDEX idx_periods_month ON budget_periods (month_id, start_day, changed_at)',
  );
  late final Index idxTransactionsMonthDay = Index(
    'idx_transactions_month_day',
    'CREATE INDEX idx_transactions_month_day ON transactions (month_id, day)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    budgetMonths,
    budgetPeriods,
    budgetPeriodsNoUpdate,
    budgetPeriodsNoDelete,
    periodFixedCosts,
    periodFixedCostsNoUpdate,
    periodFixedCostsNoDelete,
    transactions,
    savingsMoves,
    idxPeriodsMonth,
    idxTransactionsMonthDay,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'budget_periods',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'budget_periods',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'period_fixed_costs',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'period_fixed_costs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
  ]);
}

typedef $$BudgetMonthsTableCreateCompanionBuilder =
    BudgetMonthsCompanion Function({
      Value<int> id,
      required CalendarDate startDay,
      required CalendarDate endDay,
      required int salaryDay,
      required CalendarDate firstBudgetedDay,
      required int confirmedAt,
    });
typedef $$BudgetMonthsTableUpdateCompanionBuilder =
    BudgetMonthsCompanion Function({
      Value<int> id,
      Value<CalendarDate> startDay,
      Value<CalendarDate> endDay,
      Value<int> salaryDay,
      Value<CalendarDate> firstBudgetedDay,
      Value<int> confirmedAt,
    });

final class $$BudgetMonthsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetMonthsTable, MonthRow> {
  $$BudgetMonthsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BudgetPeriodsTable, List<PeriodRow>>
  _budgetPeriodsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.budgetPeriods,
    aliasName: 'budget_months__id__budget_periods__month_id',
  );

  $$BudgetPeriodsTableProcessedTableManager get budgetPeriodsRefs {
    final manager = $$BudgetPeriodsTableTableManager(
      $_db,
      $_db.budgetPeriods,
    ).filter((f) => f.monthId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetPeriodsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'budget_months__id__transactions__month_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.monthId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SavingsMovesTable, List<SavingsMoveRow>>
  _savingsMovesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.savingsMoves,
    aliasName: 'budget_months__id__savings_moves__month_id',
  );

  $$SavingsMovesTableProcessedTableManager get savingsMovesRefs {
    final manager = $$SavingsMovesTableTableManager(
      $_db,
      $_db.savingsMoves,
    ).filter((f) => f.monthId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_savingsMovesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BudgetMonthsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetMonthsTable> {
  $$BudgetMonthsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate, CalendarDate, int>
  get startDay => $composableBuilder(
    column: $table.startDay,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate, CalendarDate, int> get endDay =>
      $composableBuilder(
        column: $table.endDay,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get salaryDay => $composableBuilder(
    column: $table.salaryDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate, CalendarDate, int>
  get firstBudgetedDay => $composableBuilder(
    column: $table.firstBudgetedDay,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> budgetPeriodsRefs(
    Expression<bool> Function($$BudgetPeriodsTableFilterComposer f) f,
  ) {
    final $$BudgetPeriodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgetPeriods,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetPeriodsTableFilterComposer(
            $db: $db,
            $table: $db.budgetPeriods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> savingsMovesRefs(
    Expression<bool> Function($$SavingsMovesTableFilterComposer f) f,
  ) {
    final $$SavingsMovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savingsMoves,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsMovesTableFilterComposer(
            $db: $db,
            $table: $db.savingsMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BudgetMonthsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetMonthsTable> {
  $$BudgetMonthsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDay => $composableBuilder(
    column: $table.startDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endDay => $composableBuilder(
    column: $table.endDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get salaryDay => $composableBuilder(
    column: $table.salaryDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstBudgetedDay => $composableBuilder(
    column: $table.firstBudgetedDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetMonthsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetMonthsTable> {
  $$BudgetMonthsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CalendarDate, int> get startDay =>
      $composableBuilder(column: $table.startDay, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CalendarDate, int> get endDay =>
      $composableBuilder(column: $table.endDay, builder: (column) => column);

  GeneratedColumn<int> get salaryDay =>
      $composableBuilder(column: $table.salaryDay, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CalendarDate, int> get firstBudgetedDay =>
      $composableBuilder(
        column: $table.firstBudgetedDay,
        builder: (column) => column,
      );

  GeneratedColumn<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  Expression<T> budgetPeriodsRefs<T extends Object>(
    Expression<T> Function($$BudgetPeriodsTableAnnotationComposer a) f,
  ) {
    final $$BudgetPeriodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgetPeriods,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetPeriodsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgetPeriods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> savingsMovesRefs<T extends Object>(
    Expression<T> Function($$SavingsMovesTableAnnotationComposer a) f,
  ) {
    final $$SavingsMovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savingsMoves,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsMovesTableAnnotationComposer(
            $db: $db,
            $table: $db.savingsMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BudgetMonthsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetMonthsTable,
          MonthRow,
          $$BudgetMonthsTableFilterComposer,
          $$BudgetMonthsTableOrderingComposer,
          $$BudgetMonthsTableAnnotationComposer,
          $$BudgetMonthsTableCreateCompanionBuilder,
          $$BudgetMonthsTableUpdateCompanionBuilder,
          (MonthRow, $$BudgetMonthsTableReferences),
          MonthRow,
          PrefetchHooks Function({
            bool budgetPeriodsRefs,
            bool transactionsRefs,
            bool savingsMovesRefs,
          })
        > {
  $$BudgetMonthsTableTableManager(_$AppDatabase db, $BudgetMonthsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetMonthsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetMonthsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetMonthsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<CalendarDate> startDay = const Value.absent(),
                Value<CalendarDate> endDay = const Value.absent(),
                Value<int> salaryDay = const Value.absent(),
                Value<CalendarDate> firstBudgetedDay = const Value.absent(),
                Value<int> confirmedAt = const Value.absent(),
              }) => BudgetMonthsCompanion(
                id: id,
                startDay: startDay,
                endDay: endDay,
                salaryDay: salaryDay,
                firstBudgetedDay: firstBudgetedDay,
                confirmedAt: confirmedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required CalendarDate startDay,
                required CalendarDate endDay,
                required int salaryDay,
                required CalendarDate firstBudgetedDay,
                required int confirmedAt,
              }) => BudgetMonthsCompanion.insert(
                id: id,
                startDay: startDay,
                endDay: endDay,
                salaryDay: salaryDay,
                firstBudgetedDay: firstBudgetedDay,
                confirmedAt: confirmedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetMonthsTable, MonthRow>(table),
                  $$BudgetMonthsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                budgetPeriodsRefs = false,
                transactionsRefs = false,
                savingsMovesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (budgetPeriodsRefs) db.budgetPeriods,
                    if (transactionsRefs) db.transactions,
                    if (savingsMovesRefs) db.savingsMoves,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (budgetPeriodsRefs)
                        await $_getPrefetchedDataByColumns<
                          MonthRow,
                          $BudgetMonthsTable,
                          PeriodRow,
                          $BudgetPeriodsTable
                        >(
                          currentTable: table,
                          referencedTable: $$BudgetMonthsTableReferences
                              ._budgetPeriodsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BudgetMonthsTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetPeriodsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'month_id',
                          typedResults: items,
                        ),
                      if (transactionsRefs)
                        await $_getPrefetchedDataByColumns<
                          MonthRow,
                          $BudgetMonthsTable,
                          TransactionRow,
                          $TransactionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$BudgetMonthsTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BudgetMonthsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'month_id',
                          typedResults: items,
                        ),
                      if (savingsMovesRefs)
                        await $_getPrefetchedDataByColumns<
                          MonthRow,
                          $BudgetMonthsTable,
                          SavingsMoveRow,
                          $SavingsMovesTable
                        >(
                          currentTable: table,
                          referencedTable: $$BudgetMonthsTableReferences
                              ._savingsMovesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BudgetMonthsTableReferences(
                                db,
                                table,
                                p0,
                              ).savingsMovesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'month_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BudgetMonthsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetMonthsTable,
      MonthRow,
      $$BudgetMonthsTableFilterComposer,
      $$BudgetMonthsTableOrderingComposer,
      $$BudgetMonthsTableAnnotationComposer,
      $$BudgetMonthsTableCreateCompanionBuilder,
      $$BudgetMonthsTableUpdateCompanionBuilder,
      (MonthRow, $$BudgetMonthsTableReferences),
      MonthRow,
      PrefetchHooks Function({
        bool budgetPeriodsRefs,
        bool transactionsRefs,
        bool savingsMovesRefs,
      })
    >;
typedef $$BudgetPeriodsTableCreateCompanionBuilder =
    BudgetPeriodsCompanion Function({
      Value<int> id,
      required int monthId,
      required CalendarDate startDay,
      required int changedAt,
      required String kind,
      Value<Paise?> salaryPaise,
      Value<Paise?> targetPaise,
      Value<Paise?> moneyLeftPaise,
      Value<bool> continuedWithShortfall,
      Value<Paise> shortfallPaise,
    });
typedef $$BudgetPeriodsTableUpdateCompanionBuilder =
    BudgetPeriodsCompanion Function({
      Value<int> id,
      Value<int> monthId,
      Value<CalendarDate> startDay,
      Value<int> changedAt,
      Value<String> kind,
      Value<Paise?> salaryPaise,
      Value<Paise?> targetPaise,
      Value<Paise?> moneyLeftPaise,
      Value<bool> continuedWithShortfall,
      Value<Paise> shortfallPaise,
    });

final class $$BudgetPeriodsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetPeriodsTable, PeriodRow> {
  $$BudgetPeriodsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BudgetMonthsTable _monthIdTable(_$AppDatabase db) => db.budgetMonths
      .createAlias('budget_periods__month_id__budget_months__id');

  $$BudgetMonthsTableProcessedTableManager get monthId {
    final $_column = $_itemColumn<int>('month_id')!;

    final manager = $$BudgetMonthsTableTableManager(
      $_db,
      $_db.budgetMonths,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_monthIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PeriodFixedCostsTable, List<FixedCostRow>>
  _periodFixedCostsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.periodFixedCosts,
    aliasName: 'budget_periods__id__period_fixed_costs__period_id',
  );

  $$PeriodFixedCostsTableProcessedTableManager get periodFixedCostsRefs {
    final manager = $$PeriodFixedCostsTableTableManager(
      $_db,
      $_db.periodFixedCosts,
    ).filter((f) => f.periodId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _periodFixedCostsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BudgetPeriodsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetPeriodsTable> {
  $$BudgetPeriodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate, CalendarDate, int>
  get startDay => $composableBuilder(
    column: $table.startDay,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Paise?, Paise, int> get salaryPaise =>
      $composableBuilder(
        column: $table.salaryPaise,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Paise?, Paise, int> get targetPaise =>
      $composableBuilder(
        column: $table.targetPaise,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Paise?, Paise, int> get moneyLeftPaise =>
      $composableBuilder(
        column: $table.moneyLeftPaise,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get continuedWithShortfall => $composableBuilder(
    column: $table.continuedWithShortfall,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Paise, Paise, int> get shortfallPaise =>
      $composableBuilder(
        column: $table.shortfallPaise,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$BudgetMonthsTableFilterComposer get monthId {
    final $$BudgetMonthsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.budgetMonths,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetMonthsTableFilterComposer(
            $db: $db,
            $table: $db.budgetMonths,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> periodFixedCostsRefs(
    Expression<bool> Function($$PeriodFixedCostsTableFilterComposer f) f,
  ) {
    final $$PeriodFixedCostsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.periodFixedCosts,
      getReferencedColumn: (t) => t.periodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeriodFixedCostsTableFilterComposer(
            $db: $db,
            $table: $db.periodFixedCosts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BudgetPeriodsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetPeriodsTable> {
  $$BudgetPeriodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDay => $composableBuilder(
    column: $table.startDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get salaryPaise => $composableBuilder(
    column: $table.salaryPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetPaise => $composableBuilder(
    column: $table.targetPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get moneyLeftPaise => $composableBuilder(
    column: $table.moneyLeftPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get continuedWithShortfall => $composableBuilder(
    column: $table.continuedWithShortfall,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shortfallPaise => $composableBuilder(
    column: $table.shortfallPaise,
    builder: (column) => ColumnOrderings(column),
  );

  $$BudgetMonthsTableOrderingComposer get monthId {
    final $$BudgetMonthsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.budgetMonths,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetMonthsTableOrderingComposer(
            $db: $db,
            $table: $db.budgetMonths,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetPeriodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetPeriodsTable> {
  $$BudgetPeriodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CalendarDate, int> get startDay =>
      $composableBuilder(column: $table.startDay, builder: (column) => column);

  GeneratedColumn<int> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Paise?, int> get salaryPaise =>
      $composableBuilder(
        column: $table.salaryPaise,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Paise?, int> get targetPaise =>
      $composableBuilder(
        column: $table.targetPaise,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Paise?, int> get moneyLeftPaise =>
      $composableBuilder(
        column: $table.moneyLeftPaise,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get continuedWithShortfall => $composableBuilder(
    column: $table.continuedWithShortfall,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Paise, int> get shortfallPaise =>
      $composableBuilder(
        column: $table.shortfallPaise,
        builder: (column) => column,
      );

  $$BudgetMonthsTableAnnotationComposer get monthId {
    final $$BudgetMonthsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.budgetMonths,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetMonthsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgetMonths,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> periodFixedCostsRefs<T extends Object>(
    Expression<T> Function($$PeriodFixedCostsTableAnnotationComposer a) f,
  ) {
    final $$PeriodFixedCostsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.periodFixedCosts,
      getReferencedColumn: (t) => t.periodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeriodFixedCostsTableAnnotationComposer(
            $db: $db,
            $table: $db.periodFixedCosts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BudgetPeriodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetPeriodsTable,
          PeriodRow,
          $$BudgetPeriodsTableFilterComposer,
          $$BudgetPeriodsTableOrderingComposer,
          $$BudgetPeriodsTableAnnotationComposer,
          $$BudgetPeriodsTableCreateCompanionBuilder,
          $$BudgetPeriodsTableUpdateCompanionBuilder,
          (PeriodRow, $$BudgetPeriodsTableReferences),
          PeriodRow,
          PrefetchHooks Function({bool monthId, bool periodFixedCostsRefs})
        > {
  $$BudgetPeriodsTableTableManager(_$AppDatabase db, $BudgetPeriodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetPeriodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetPeriodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetPeriodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> monthId = const Value.absent(),
                Value<CalendarDate> startDay = const Value.absent(),
                Value<int> changedAt = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<Paise?> salaryPaise = const Value.absent(),
                Value<Paise?> targetPaise = const Value.absent(),
                Value<Paise?> moneyLeftPaise = const Value.absent(),
                Value<bool> continuedWithShortfall = const Value.absent(),
                Value<Paise> shortfallPaise = const Value.absent(),
              }) => BudgetPeriodsCompanion(
                id: id,
                monthId: monthId,
                startDay: startDay,
                changedAt: changedAt,
                kind: kind,
                salaryPaise: salaryPaise,
                targetPaise: targetPaise,
                moneyLeftPaise: moneyLeftPaise,
                continuedWithShortfall: continuedWithShortfall,
                shortfallPaise: shortfallPaise,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int monthId,
                required CalendarDate startDay,
                required int changedAt,
                required String kind,
                Value<Paise?> salaryPaise = const Value.absent(),
                Value<Paise?> targetPaise = const Value.absent(),
                Value<Paise?> moneyLeftPaise = const Value.absent(),
                Value<bool> continuedWithShortfall = const Value.absent(),
                Value<Paise> shortfallPaise = const Value.absent(),
              }) => BudgetPeriodsCompanion.insert(
                id: id,
                monthId: monthId,
                startDay: startDay,
                changedAt: changedAt,
                kind: kind,
                salaryPaise: salaryPaise,
                targetPaise: targetPaise,
                moneyLeftPaise: moneyLeftPaise,
                continuedWithShortfall: continuedWithShortfall,
                shortfallPaise: shortfallPaise,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetPeriodsTable, PeriodRow>(table),
                  $$BudgetPeriodsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({monthId = false, periodFixedCostsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (periodFixedCostsRefs) db.periodFixedCosts,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (monthId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.monthId,
                            referencedTable: $$BudgetPeriodsTableReferences
                                ._monthIdTable(db),
                            referencedColumn: $$BudgetPeriodsTableReferences
                                ._monthIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (periodFixedCostsRefs)
                        await $_getPrefetchedDataByColumns<
                          PeriodRow,
                          $BudgetPeriodsTable,
                          FixedCostRow,
                          $PeriodFixedCostsTable
                        >(
                          currentTable: table,
                          referencedTable: $$BudgetPeriodsTableReferences
                              ._periodFixedCostsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BudgetPeriodsTableReferences(
                                db,
                                table,
                                p0,
                              ).periodFixedCostsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'period_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BudgetPeriodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetPeriodsTable,
      PeriodRow,
      $$BudgetPeriodsTableFilterComposer,
      $$BudgetPeriodsTableOrderingComposer,
      $$BudgetPeriodsTableAnnotationComposer,
      $$BudgetPeriodsTableCreateCompanionBuilder,
      $$BudgetPeriodsTableUpdateCompanionBuilder,
      (PeriodRow, $$BudgetPeriodsTableReferences),
      PeriodRow,
      PrefetchHooks Function({bool monthId, bool periodFixedCostsRefs})
    >;
typedef $$PeriodFixedCostsTableCreateCompanionBuilder =
    PeriodFixedCostsCompanion Function({
      Value<int> id,
      required int periodId,
      required int position,
      required String name,
      required Paise amountPaise,
    });
typedef $$PeriodFixedCostsTableUpdateCompanionBuilder =
    PeriodFixedCostsCompanion Function({
      Value<int> id,
      Value<int> periodId,
      Value<int> position,
      Value<String> name,
      Value<Paise> amountPaise,
    });

final class $$PeriodFixedCostsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PeriodFixedCostsTable, FixedCostRow> {
  $$PeriodFixedCostsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BudgetPeriodsTable _periodIdTable(_$AppDatabase db) => db
      .budgetPeriods
      .createAlias('period_fixed_costs__period_id__budget_periods__id');

  $$BudgetPeriodsTableProcessedTableManager get periodId {
    final $_column = $_itemColumn<int>('period_id')!;

    final manager = $$BudgetPeriodsTableTableManager(
      $_db,
      $_db.budgetPeriods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_periodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PeriodFixedCostsTableFilterComposer
    extends Composer<_$AppDatabase, $PeriodFixedCostsTable> {
  $$PeriodFixedCostsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Paise, Paise, int> get amountPaise =>
      $composableBuilder(
        column: $table.amountPaise,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$BudgetPeriodsTableFilterComposer get periodId {
    final $$BudgetPeriodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.periodId,
      referencedTable: $db.budgetPeriods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetPeriodsTableFilterComposer(
            $db: $db,
            $table: $db.budgetPeriods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeriodFixedCostsTableOrderingComposer
    extends Composer<_$AppDatabase, $PeriodFixedCostsTable> {
  $$PeriodFixedCostsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  $$BudgetPeriodsTableOrderingComposer get periodId {
    final $$BudgetPeriodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.periodId,
      referencedTable: $db.budgetPeriods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetPeriodsTableOrderingComposer(
            $db: $db,
            $table: $db.budgetPeriods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeriodFixedCostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeriodFixedCostsTable> {
  $$PeriodFixedCostsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Paise, int> get amountPaise =>
      $composableBuilder(
        column: $table.amountPaise,
        builder: (column) => column,
      );

  $$BudgetPeriodsTableAnnotationComposer get periodId {
    final $$BudgetPeriodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.periodId,
      referencedTable: $db.budgetPeriods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetPeriodsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgetPeriods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeriodFixedCostsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeriodFixedCostsTable,
          FixedCostRow,
          $$PeriodFixedCostsTableFilterComposer,
          $$PeriodFixedCostsTableOrderingComposer,
          $$PeriodFixedCostsTableAnnotationComposer,
          $$PeriodFixedCostsTableCreateCompanionBuilder,
          $$PeriodFixedCostsTableUpdateCompanionBuilder,
          (FixedCostRow, $$PeriodFixedCostsTableReferences),
          FixedCostRow,
          PrefetchHooks Function({bool periodId})
        > {
  $$PeriodFixedCostsTableTableManager(
    _$AppDatabase db,
    $PeriodFixedCostsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeriodFixedCostsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeriodFixedCostsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeriodFixedCostsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> periodId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<Paise> amountPaise = const Value.absent(),
              }) => PeriodFixedCostsCompanion(
                id: id,
                periodId: periodId,
                position: position,
                name: name,
                amountPaise: amountPaise,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int periodId,
                required int position,
                required String name,
                required Paise amountPaise,
              }) => PeriodFixedCostsCompanion.insert(
                id: id,
                periodId: periodId,
                position: position,
                name: name,
                amountPaise: amountPaise,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PeriodFixedCostsTable, FixedCostRow>(table),
                  $$PeriodFixedCostsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({periodId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (periodId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.periodId,
                        referencedTable: $$PeriodFixedCostsTableReferences
                            ._periodIdTable(db),
                        referencedColumn: $$PeriodFixedCostsTableReferences
                            ._periodIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PeriodFixedCostsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeriodFixedCostsTable,
      FixedCostRow,
      $$PeriodFixedCostsTableFilterComposer,
      $$PeriodFixedCostsTableOrderingComposer,
      $$PeriodFixedCostsTableAnnotationComposer,
      $$PeriodFixedCostsTableCreateCompanionBuilder,
      $$PeriodFixedCostsTableUpdateCompanionBuilder,
      (FixedCostRow, $$PeriodFixedCostsTableReferences),
      FixedCostRow,
      PrefetchHooks Function({bool periodId})
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required int monthId,
      required CalendarDate day,
      required Paise amountPaise,
      Value<String> direction,
      Value<String> note,
      Value<String> source,
      Value<String?> category,
      required int createdAt,
      required int editedAt,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<int> monthId,
      Value<CalendarDate> day,
      Value<Paise> amountPaise,
      Value<String> direction,
      Value<String> note,
      Value<String> source,
      Value<String?> category,
      Value<int> createdAt,
      Value<int> editedAt,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BudgetMonthsTable _monthIdTable(_$AppDatabase db) =>
      db.budgetMonths.createAlias('transactions__month_id__budget_months__id');

  $$BudgetMonthsTableProcessedTableManager get monthId {
    final $_column = $_itemColumn<int>('month_id')!;

    final manager = $$BudgetMonthsTableTableManager(
      $_db,
      $_db.budgetMonths,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_monthIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate, CalendarDate, int> get day =>
      $composableBuilder(
        column: $table.day,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Paise, Paise, int> get amountPaise =>
      $composableBuilder(
        column: $table.amountPaise,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BudgetMonthsTableFilterComposer get monthId {
    final $$BudgetMonthsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.budgetMonths,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetMonthsTableFilterComposer(
            $db: $db,
            $table: $db.budgetMonths,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BudgetMonthsTableOrderingComposer get monthId {
    final $$BudgetMonthsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.budgetMonths,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetMonthsTableOrderingComposer(
            $db: $db,
            $table: $db.budgetMonths,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CalendarDate, int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Paise, int> get amountPaise =>
      $composableBuilder(
        column: $table.amountPaise,
        builder: (column) => column,
      );

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  $$BudgetMonthsTableAnnotationComposer get monthId {
    final $$BudgetMonthsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.budgetMonths,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetMonthsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgetMonths,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TransactionRow, $$TransactionsTableReferences),
          TransactionRow,
          PrefetchHooks Function({bool monthId})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> monthId = const Value.absent(),
                Value<CalendarDate> day = const Value.absent(),
                Value<Paise> amountPaise = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> editedAt = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                monthId: monthId,
                day: day,
                amountPaise: amountPaise,
                direction: direction,
                note: note,
                source: source,
                category: category,
                createdAt: createdAt,
                editedAt: editedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int monthId,
                required CalendarDate day,
                required Paise amountPaise,
                Value<String> direction = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> category = const Value.absent(),
                required int createdAt,
                required int editedAt,
              }) => TransactionsCompanion.insert(
                id: id,
                monthId: monthId,
                day: day,
                amountPaise: amountPaise,
                direction: direction,
                note: note,
                source: source,
                category: category,
                createdAt: createdAt,
                editedAt: editedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, TransactionRow>(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({monthId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (monthId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.monthId,
                        referencedTable: $$TransactionsTableReferences
                            ._monthIdTable(db),
                        referencedColumn: $$TransactionsTableReferences
                            ._monthIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TransactionRow, $$TransactionsTableReferences),
      TransactionRow,
      PrefetchHooks Function({bool monthId})
    >;
typedef $$SavingsMovesTableCreateCompanionBuilder =
    SavingsMovesCompanion Function({
      Value<int> id,
      required int monthId,
      required CalendarDate coveredDay,
      required Paise amountPaise,
      required int madeAt,
    });
typedef $$SavingsMovesTableUpdateCompanionBuilder =
    SavingsMovesCompanion Function({
      Value<int> id,
      Value<int> monthId,
      Value<CalendarDate> coveredDay,
      Value<Paise> amountPaise,
      Value<int> madeAt,
    });

final class $$SavingsMovesTableReferences
    extends BaseReferences<_$AppDatabase, $SavingsMovesTable, SavingsMoveRow> {
  $$SavingsMovesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BudgetMonthsTable _monthIdTable(_$AppDatabase db) =>
      db.budgetMonths.createAlias('savings_moves__month_id__budget_months__id');

  $$BudgetMonthsTableProcessedTableManager get monthId {
    final $_column = $_itemColumn<int>('month_id')!;

    final manager = $$BudgetMonthsTableTableManager(
      $_db,
      $_db.budgetMonths,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_monthIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SavingsMovesTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsMovesTable> {
  $$SavingsMovesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate, CalendarDate, int>
  get coveredDay => $composableBuilder(
    column: $table.coveredDay,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Paise, Paise, int> get amountPaise =>
      $composableBuilder(
        column: $table.amountPaise,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get madeAt => $composableBuilder(
    column: $table.madeAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BudgetMonthsTableFilterComposer get monthId {
    final $$BudgetMonthsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.budgetMonths,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetMonthsTableFilterComposer(
            $db: $db,
            $table: $db.budgetMonths,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavingsMovesTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsMovesTable> {
  $$SavingsMovesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coveredDay => $composableBuilder(
    column: $table.coveredDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get madeAt => $composableBuilder(
    column: $table.madeAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BudgetMonthsTableOrderingComposer get monthId {
    final $$BudgetMonthsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.budgetMonths,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetMonthsTableOrderingComposer(
            $db: $db,
            $table: $db.budgetMonths,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavingsMovesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsMovesTable> {
  $$SavingsMovesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CalendarDate, int> get coveredDay =>
      $composableBuilder(
        column: $table.coveredDay,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Paise, int> get amountPaise =>
      $composableBuilder(
        column: $table.amountPaise,
        builder: (column) => column,
      );

  GeneratedColumn<int> get madeAt =>
      $composableBuilder(column: $table.madeAt, builder: (column) => column);

  $$BudgetMonthsTableAnnotationComposer get monthId {
    final $$BudgetMonthsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.budgetMonths,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetMonthsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgetMonths,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavingsMovesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavingsMovesTable,
          SavingsMoveRow,
          $$SavingsMovesTableFilterComposer,
          $$SavingsMovesTableOrderingComposer,
          $$SavingsMovesTableAnnotationComposer,
          $$SavingsMovesTableCreateCompanionBuilder,
          $$SavingsMovesTableUpdateCompanionBuilder,
          (SavingsMoveRow, $$SavingsMovesTableReferences),
          SavingsMoveRow,
          PrefetchHooks Function({bool monthId})
        > {
  $$SavingsMovesTableTableManager(_$AppDatabase db, $SavingsMovesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsMovesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsMovesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsMovesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> monthId = const Value.absent(),
                Value<CalendarDate> coveredDay = const Value.absent(),
                Value<Paise> amountPaise = const Value.absent(),
                Value<int> madeAt = const Value.absent(),
              }) => SavingsMovesCompanion(
                id: id,
                monthId: monthId,
                coveredDay: coveredDay,
                amountPaise: amountPaise,
                madeAt: madeAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int monthId,
                required CalendarDate coveredDay,
                required Paise amountPaise,
                required int madeAt,
              }) => SavingsMovesCompanion.insert(
                id: id,
                monthId: monthId,
                coveredDay: coveredDay,
                amountPaise: amountPaise,
                madeAt: madeAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavingsMovesTable, SavingsMoveRow>(table),
                  $$SavingsMovesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({monthId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (monthId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.monthId,
                        referencedTable: $$SavingsMovesTableReferences
                            ._monthIdTable(db),
                        referencedColumn: $$SavingsMovesTableReferences
                            ._monthIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SavingsMovesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavingsMovesTable,
      SavingsMoveRow,
      $$SavingsMovesTableFilterComposer,
      $$SavingsMovesTableOrderingComposer,
      $$SavingsMovesTableAnnotationComposer,
      $$SavingsMovesTableCreateCompanionBuilder,
      $$SavingsMovesTableUpdateCompanionBuilder,
      (SavingsMoveRow, $$SavingsMovesTableReferences),
      SavingsMoveRow,
      PrefetchHooks Function({bool monthId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BudgetMonthsTableTableManager get budgetMonths =>
      $$BudgetMonthsTableTableManager(_db, _db.budgetMonths);
  $$BudgetPeriodsTableTableManager get budgetPeriods =>
      $$BudgetPeriodsTableTableManager(_db, _db.budgetPeriods);
  $$PeriodFixedCostsTableTableManager get periodFixedCosts =>
      $$PeriodFixedCostsTableTableManager(_db, _db.periodFixedCosts);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$SavingsMovesTableTableManager get savingsMoves =>
      $$SavingsMovesTableTableManager(_db, _db.savingsMoves);
}
