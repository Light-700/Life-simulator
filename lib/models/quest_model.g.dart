// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestModelAdapter extends TypeAdapter<QuestModel> {
  @override
  final int typeId = 1;

  @override
  QuestModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      questType: fields[3] as String,
      difficulty: fields[4] as String,
      objectives: (fields[5] as List).cast<String>(),
      rewards: (fields[6] as Map).cast<String, int>(),
      category: fields[7] as String,
      createdAt: fields[8] as DateTime,
      expiresAt: fields[10] as DateTime,
      completedAt: fields[9] as DateTime?,
      isCompleted: fields[11] as bool,
      progress: fields[12] as double,
      unlockLevel: fields[13] as int,
      metadata: (fields[14] as Map?)?.cast<String, dynamic>(),
      isMandatory: fields[15] as bool,
      penaltyAmount: fields[16] as int,
      penaltyType: fields[17] as String,
    );
  }

  @override
  void write(BinaryWriter writer, QuestModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.questType)
      ..writeByte(4)
      ..write(obj.difficulty)
      ..writeByte(5)
      ..write(obj.objectives)
      ..writeByte(6)
      ..write(obj.rewards)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.completedAt)
      ..writeByte(10)
      ..write(obj.expiresAt)
      ..writeByte(11)
      ..write(obj.isCompleted)
      ..writeByte(12)
      ..write(obj.progress)
      ..writeByte(13)
      ..write(obj.unlockLevel)
      ..writeByte(14)
      ..write(obj.metadata)
      ..writeByte(15)
      ..write(obj.isMandatory)
      ..writeByte(16)
      ..write(obj.penaltyAmount)
      ..writeByte(17)
      ..write(obj.penaltyType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailyQuestAdapter extends TypeAdapter<DailyQuest> {
  @override
  final int typeId = 2;

  @override
  DailyQuest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyQuest(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      rewards: (fields[6] as Map).cast<String, int>(),
      objectives: (fields[5] as List).cast<String>(),
      isMandatory: fields[15] as bool,
      penaltyAmount: fields[16] as int,
      penaltyType: fields[17] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DailyQuest obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.questType)
      ..writeByte(4)
      ..write(obj.difficulty)
      ..writeByte(5)
      ..write(obj.objectives)
      ..writeByte(6)
      ..write(obj.rewards)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.completedAt)
      ..writeByte(10)
      ..write(obj.expiresAt)
      ..writeByte(11)
      ..write(obj.isCompleted)
      ..writeByte(12)
      ..write(obj.progress)
      ..writeByte(13)
      ..write(obj.unlockLevel)
      ..writeByte(14)
      ..write(obj.metadata)
      ..writeByte(15)
      ..write(obj.isMandatory)
      ..writeByte(16)
      ..write(obj.penaltyAmount)
      ..writeByte(17)
      ..write(obj.penaltyType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyQuestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
