enum JobCategory { industrial, event }

class SkillDef {
  final String id;
  final String en;
  final String ta;
  final JobCategory category;
  const SkillDef(this.id, this.en, this.ta, this.category);
}

const allSkills = [
  // Industrial
  SkillDef('spinning', 'Spinning', 'ஸ்பின்னிங்', JobCategory.industrial),
  SkillDef('weaving', 'Weaving', 'நெசவு', JobCategory.industrial),
  SkillDef('welding', 'Welding', 'வெல்டிங்', JobCategory.industrial),
  SkillDef('lathe', 'Lathe', 'லேத்', JobCategory.industrial),
  SkillDef('packing', 'Packing', 'பேக்கிங்', JobCategory.industrial),
  // Events
  SkillDef('event_coordinator', 'Event Coordinator', 'நிகழ்ச்சி ஒருங்கிணைப்பாளர்', JobCategory.event),
  SkillDef('stage_decor', 'Stage / Decor Setup', 'மேடை அலங்காரம்', JobCategory.event),
  SkillDef('catering', 'Catering Helper', 'கேட்டரிங் உதவி', JobCategory.event),
  SkillDef('loading', 'Loading / Unloading', 'லோடு ஏற்றி இறக்கல்', JobCategory.event),
  SkillDef('security', 'Security / Crowd', 'பாதுகாப்பு', JobCategory.event),
];

List<SkillDef> skillsFor(JobCategory c) =>
    allSkills.where((s) => s.category == c).toList();