abstract final class GameConstants {
  static const int ticRate = 35;
  static const double msPerTic = 1000.0 / ticRate;
  static const int msPerTicInt = 1000 ~/ ticRate;

  static const int maxPlayers = 4;
  static const int maxHealth = 100;
  static const int maxArmor = 200;
  static const int maxAmmo = 200;

  static const int meleeRange = 64 << 16;
  static const int missileRange = 32 * 64 << 16;
}

enum GameMode {
  shareware,
  registered,
  commercial,
  retail,
  indetermined,
}

enum GameMission {
  doom,
  doom2,
  packTnt,
  packPlut,
  none,
}

enum Language {
  english,
  french,
  german,
  unknown,
}

enum Skill {
  imTooYoungToDie,
  heyNotTooRough,
  hurtMePlenty,
  ultraViolence,
  nightmare,
}

enum GameState {
  level,
  intermission,
  finale,
  demoScreen,
}

enum GameAction {
  nothing,
  loadLevel,
  newGame,
  loadGame,
  saveGame,
  playDemo,
  recordDemo,
  completed,
  victory,
  worldDone,
  screenshot,
}

enum PlayerState {
  live,
  dead,
  reborn,
}

enum AmmoType {
  clip,
  shell,
  cell,
  missile,
  noAmmo,
}

enum WeaponType {
  fist,
  pistol,
  shotgun,
  chaingun,
  missile,
  plasma,
  bfg,
  chainsaw,
  superShotgun,
  numWeapons,
  noChange,
}

enum PowerType {
  invulnerability,
  strength,
  invisibility,
  ironFeet,
  allMap,
  infrared,
  numPowers,
}

enum CardType {
  blueCard,
  yellowCard,
  redCard,
  blueSkull,
  yellowSkull,
  redSkull,
  numCards,
}
