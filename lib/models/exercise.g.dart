// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 2;

  @override
  Exercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exercise(
      id: fields[0] as String,
      name: fields[1] as String,
      defaultType: fields[2] as String,
      description: fields[3] as String,
      requiresExternal: fields[4] as bool,
      equipment: (fields[5] as List?)?.cast<String>(),
      suitableAtHome: fields[6] as bool,
      suitableAtGym: fields[7] as bool,
      mediaUrls: (fields[8] as List?)?.cast<String>(),
      category: fields[9] as String,
      difficulty: fields[10] as String,
      locations: (fields[11] as List?)?.cast<String>(),
      instructions: fields[12] as String,
      commonMistakes: fields[13] as String,
      benefits: fields[14] as String,
      safetyTips: fields[15] as String,
      primaryMuscles: (fields[16] as List?)?.cast<String>(),
      secondaryMuscles: (fields[17] as List?)?.cast<String>(),
      setsRecommended: fields[18] as int,
      repsRecommended: fields[19] as int,
      timeRecommended: fields[20] as String?,
      caloriesBurnEstimate: fields[21] as int,
      progressionLevel: fields[22] as String,
      regressionLevel: fields[23] as String,
      imageUrl: fields[24] as String,
      gifUrl: fields[25] as String,
      videoUrl: fields[26] as String,
      audioCue: fields[27] as String,
      tags: (fields[28] as List?)?.cast<String>(),
      indoorOutdoor: fields[29] as String,
      isFavorite: fields[30] as bool,
      isBodyweight: fields[31] as bool,
      requiresPartner: fields[32] as bool,
      warmupOrMain: fields[33] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(34)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.defaultType)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.requiresExternal)
      ..writeByte(5)
      ..write(obj.equipment)
      ..writeByte(6)
      ..write(obj.suitableAtHome)
      ..writeByte(7)
      ..write(obj.suitableAtGym)
      ..writeByte(8)
      ..write(obj.mediaUrls)
      ..writeByte(9)
      ..write(obj.category)
      ..writeByte(10)
      ..write(obj.difficulty)
      ..writeByte(11)
      ..write(obj.locations)
      ..writeByte(12)
      ..write(obj.instructions)
      ..writeByte(13)
      ..write(obj.commonMistakes)
      ..writeByte(14)
      ..write(obj.benefits)
      ..writeByte(15)
      ..write(obj.safetyTips)
      ..writeByte(16)
      ..write(obj.primaryMuscles)
      ..writeByte(17)
      ..write(obj.secondaryMuscles)
      ..writeByte(18)
      ..write(obj.setsRecommended)
      ..writeByte(19)
      ..write(obj.repsRecommended)
      ..writeByte(20)
      ..write(obj.timeRecommended)
      ..writeByte(21)
      ..write(obj.caloriesBurnEstimate)
      ..writeByte(22)
      ..write(obj.progressionLevel)
      ..writeByte(23)
      ..write(obj.regressionLevel)
      ..writeByte(24)
      ..write(obj.imageUrl)
      ..writeByte(25)
      ..write(obj.gifUrl)
      ..writeByte(26)
      ..write(obj.videoUrl)
      ..writeByte(27)
      ..write(obj.audioCue)
      ..writeByte(28)
      ..write(obj.tags)
      ..writeByte(29)
      ..write(obj.indoorOutdoor)
      ..writeByte(30)
      ..write(obj.isFavorite)
      ..writeByte(31)
      ..write(obj.isBodyweight)
      ..writeByte(32)
      ..write(obj.requiresPartner)
      ..writeByte(33)
      ..write(obj.warmupOrMain);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
