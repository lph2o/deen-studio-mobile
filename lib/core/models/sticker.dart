class Sticker {
  final String id;
  final String name;
  final String category; // 'emotions', 'shapes', 'symbols', 'nature', 'food', 'arabic', 'social', 'celebration'
  final String emoji;    // the emoji character itself
  final double defaultSize;

  const Sticker({
    required this.id,
    required this.name,
    required this.category,
    required this.emoji,
    this.defaultSize = 48.0,
  });
}

const kBuiltInStickers = [
  // ── Emotions ──
  Sticker(id: 's1', name: 'Heart', category: 'emotions', emoji: '\u2764\uFE0F'),
  Sticker(id: 's2', name: 'Star Eyes', category: 'emotions', emoji: '\uD83E\uDD29'),
  Sticker(id: 's3', name: 'Fire', category: 'emotions', emoji: '\uD83D\uDD25'),
  Sticker(id: 's4', name: 'Crying', category: 'emotions', emoji: '\uD83D\uDE22'),
  Sticker(id: 's5', name: 'Love', category: 'emotions', emoji: '\uD83D\uDE0D'),
  Sticker(id: 's17', name: 'Laugh', category: 'emotions', emoji: '\uD83D\uDE02'),
  Sticker(id: 's18', name: 'Wink', category: 'emotions', emoji: '\uD83D\uDE09'),
  Sticker(id: 's19', name: 'Cool', category: 'emotions', emoji: '\uD83D\uDE0E'),
  Sticker(id: 's20', name: 'Nerd', category: 'emotions', emoji: '\uD83E\uDD13'),
  Sticker(id: 's21', name: 'Sick', category: 'emotions', emoji: '\uD83E\uDD22'),
  Sticker(id: 's22', name: 'Angry', category: 'emotions', emoji: '\uD83D\uDE21'),
  Sticker(id: 's23', name: 'Surprised', category: 'emotions', emoji: '\uD83D\uDE32'),
  Sticker(id: 's24', name: 'Thinking', category: 'emotions', emoji: '\uD83E\uDD14'),
  Sticker(id: 's25', name: 'Sleeping', category: 'emotions', emoji: '\uD83D\uDE34'),
  Sticker(id: 's26', name: 'Party', category: 'emotions', emoji: '\uD83E\uDD73'),
  Sticker(id: 's27', name: 'Shy', category: 'emotions', emoji: '\uD83E\uDEE3'),
  Sticker(id: 's28', name: 'Sad', category: 'emotions', emoji: '\uD83D\uDE14'),
  Sticker(id: 's29', name: 'Kiss', category: 'emotions', emoji: '\uD83D\uDE18'),
  Sticker(id: 's30', name: 'Devil', category: 'emotions', emoji: '\uD83D\uDE08'),
  Sticker(id: 's31', name: 'Cowboy', category: 'emotions', emoji: '\uD83E\uDD20'),
  Sticker(id: 's32', name: 'Mind Blown', category: 'emotions', emoji: '\uD83E\uDD2F'),
  Sticker(id: 's33', name: 'Salute', category: 'emotions', emoji: '\uD83E\uDEF2'),

  // ── Shapes ──
  Sticker(id: 's6', name: 'Star', category: 'shapes', emoji: '\u2B50'),
  Sticker(id: 's7', name: 'Sparkle', category: 'shapes', emoji: '\u2728'),
  Sticker(id: 's8', name: 'Arrow', category: 'shapes', emoji: '\u27A1\uFE0F'),
  Sticker(id: 's34', name: 'Arrow Up', category: 'shapes', emoji: '\u2B06\uFE0F'),
  Sticker(id: 's35', name: 'Arrow Down', category: 'shapes', emoji: '\u2B07\uFE0F'),
  Sticker(id: 's36', name: 'Arrow Left', category: 'shapes', emoji: '\u2B05\uFE0F'),
  Sticker(id: 's37', name: 'Circle', category: 'shapes', emoji: '\uD83D\uDD34'),
  Sticker(id: 's38', name: 'Blue Circle', category: 'shapes', emoji: '\uD83D\uDD35'),
  Sticker(id: 's39', name: 'Green Circle', category: 'shapes', emoji: '\uD83D\uDFE2'),
  Sticker(id: 's40', name: 'Diamond', category: 'shapes', emoji: '\uD83D\uDD37'),
  Sticker(id: 's41', name: 'Badge', category: 'shapes', emoji: '\uD83C\uDFC5'),
  Sticker(id: 's42', name: 'Shield', category: 'shapes', emoji: '\uD83D\uDEE1\uFE0F'),
  Sticker(id: 's43', name: 'Flag', category: 'shapes', emoji: '\uD83D\uDEA9'),
  Sticker(id: 's44', name: 'Lightning', category: 'shapes', emoji: '\u26A1'),

  // ── Symbols ──
  Sticker(id: 's9', name: 'Check', category: 'symbols', emoji: '\u2705'),
  Sticker(id: 's10', name: 'Warning', category: 'symbols', emoji: '\u26A0\uFE0F'),
  Sticker(id: 's45', name: 'Music', category: 'symbols', emoji: '\uD83C\uDFB5'),
  Sticker(id: 's46', name: 'Music Note', category: 'symbols', emoji: '\uD83C\uDFB6'),
  Sticker(id: 's47', name: 'Camera', category: 'symbols', emoji: '\uD83D\uDCF7'),
  Sticker(id: 's48', name: 'Video', category: 'symbols', emoji: '\uD83D\uDCF9'),
  Sticker(id: 's49', name: 'Phone', category: 'symbols', emoji: '\uD83D\uDCF1'),
  Sticker(id: 's50', name: 'Clock', category: 'symbols', emoji: '\u23F0'),
  Sticker(id: 's51', name: 'Cross', category: 'symbols', emoji: '\u274C'),
  Sticker(id: 's52', name: 'Question', category: 'symbols', emoji: '\u2753'),
  Sticker(id: 's53', name: 'Exclamation', category: 'symbols', emoji: '\u2757'),
  Sticker(id: 's54', name: 'Infinity', category: 'symbols', emoji: '\u267E\uFE0F'),
  Sticker(id: 's55', name: 'Star of David', category: 'symbols', emoji: '\u2721\uFE0F'),
  Sticker(id: 's56', name: 'Om', category: 'symbols', emoji: '\uD83D\uDD49\uFE0F'),
  Sticker(id: 's57', name: 'Peace', category: 'symbols', emoji: '\u262E\uFE0F'),
  Sticker(id: 's58', name: 'Crown', category: 'symbols', emoji: '\uD83D\uDC51'),
  Sticker(id: 's59', name: 'Key', category: 'symbols', emoji: '\uD83D\uDD11'),
  Sticker(id: 's60', name: 'Lock', category: 'symbols', emoji: '\uD83D\uDD12'),

  // ── Nature ──
  Sticker(id: 's11', name: 'Sun', category: 'nature', emoji: '\u2600\uFE0F'),
  Sticker(id: 's12', name: 'Moon', category: 'nature', emoji: '\uD83C\uDF19'),
  Sticker(id: 's61', name: 'Cloud', category: 'nature', emoji: '\u2601\uFE0F'),
  Sticker(id: 's62', name: 'Rainbow', category: 'nature', emoji: '\uD83C\uDF08'),
  Sticker(id: 's63', name: 'Snowflake', category: 'nature', emoji: '\u2744\uFE0F'),
  Sticker(id: 's64', name: 'Thunder', category: 'nature', emoji: '\u26C8\uFE0F'),
  Sticker(id: 's65', name: 'Flower', category: 'nature', emoji: '\uD83C\uDF38'),
  Sticker(id: 's66', name: 'Rose', category: 'nature', emoji: '\uD83C\uDF39'),
  Sticker(id: 's67', name: 'Sunflower', category: 'nature', emoji: '\uD83C\uDF3B'),
  Sticker(id: 's68', name: 'Tree', category: 'nature', emoji: '\uD83C\uDF33'),
  Sticker(id: 's69', name: 'Leaf', category: 'nature', emoji: '\uD83C\uDF43'),
  Sticker(id: 's70', name: 'Cactus', category: 'nature', emoji: '\uD83C\uDF35'),
  Sticker(id: 's71', name: 'Butterfly', category: 'nature', emoji: '\uD83E\uDD8B'),
  Sticker(id: 's72', name: 'Bird', category: 'nature', emoji: '\uD83D\uDC26'),
  Sticker(id: 's73', name: 'Dove', category: 'nature', emoji: '\uD83D\uDD4A\uFE0F'),
  Sticker(id: 's74', name: 'Cat', category: 'nature', emoji: '\uD83D\uDC31'),
  Sticker(id: 's75', name: 'Dog', category: 'nature', emoji: '\uD83D\uDC36'),
  Sticker(id: 's76', name: 'Water', category: 'nature', emoji: '\uD83D\uDCA7'),
  Sticker(id: 's77', name: 'Mountain', category: 'nature', emoji: '\u26F0\uFE0F'),

  // ── Arabic / Islamic ──
  Sticker(id: 's13', name: 'Crescent', category: 'arabic', emoji: '\u262A\uFE0F'),
  Sticker(id: 's14', name: 'Hands Praying', category: 'arabic', emoji: '\uD83E\uDD32'),
  Sticker(id: 's15', name: 'Kaaba', category: 'arabic', emoji: '\uD83D\uDD4B'),
  Sticker(id: 's16', name: 'Mosque', category: 'arabic', emoji: '\uD83D\uDD4C'),
  Sticker(id: 's78', name: 'Beads', category: 'arabic', emoji: '\uD83D\uDCFF'),
  Sticker(id: 's79', name: 'Lamp', category: 'arabic', emoji: '\uD83E\uDE94'),
  Sticker(id: 's80', name: 'Book', category: 'arabic', emoji: '\uD83D\uDCD6'),
  Sticker(id: 's81', name: 'Ramadan', category: 'arabic', emoji: '\uD83C\uDF19'),

  // ── Social ──
  Sticker(id: 's82', name: 'Thumbs Up', category: 'social', emoji: '\uD83D\uDC4D'),
  Sticker(id: 's83', name: 'Thumbs Down', category: 'social', emoji: '\uD83D\uDC4E'),
  Sticker(id: 's84', name: 'Clap', category: 'social', emoji: '\uD83D\uDC4F'),
  Sticker(id: 's85', name: 'Wave', category: 'social', emoji: '\uD83D\uDC4B'),
  Sticker(id: 's86', name: 'Pray', category: 'social', emoji: '\uD83D\uDE4F'),
  Sticker(id: 's87', name: 'Raise Hands', category: 'social', emoji: '\uD83D\uDE4C'),
  Sticker(id: 's88', name: 'Point Up', category: 'social', emoji: '\u261D\uFE0F'),
  Sticker(id: 's89', name: 'OK', category: 'social', emoji: '\uD83D\uDC4C'),
  Sticker(id: 's90', name: 'Fist', category: 'social', emoji: '\u270A'),
  Sticker(id: 's91', name: 'Muscle', category: 'social', emoji: '\uD83D\uDCAA'),
  Sticker(id: 's92', name: 'Handshake', category: 'social', emoji: '\uD83E\uDD1D'),

  // ── Celebration ──
  Sticker(id: 's93', name: 'Confetti', category: 'celebration', emoji: '\uD83C\uDF8A'),
  Sticker(id: 's94', name: 'Party Popper', category: 'celebration', emoji: '\uD83C\uDF89'),
  Sticker(id: 's95', name: 'Balloon', category: 'celebration', emoji: '\uD83C\uDF88'),
  Sticker(id: 's96', name: 'Trophy', category: 'celebration', emoji: '\uD83C\uDFC6'),
  Sticker(id: 's97', name: 'Medal', category: 'celebration', emoji: '\uD83C\uDFC5'),
  Sticker(id: 's98', name: 'Gift', category: 'celebration', emoji: '\uD83C\uDF81'),
  Sticker(id: 's99', name: 'Cake', category: 'celebration', emoji: '\uD83C\uDF82'),
  Sticker(id: 's100', name: 'Champagne', category: 'celebration', emoji: '\uD83C\uDF7E'),
  Sticker(id: 's101', name: 'Fireworks', category: 'celebration', emoji: '\uD83C\uDF86'),
  Sticker(id: 's102', name: 'Sparkler', category: 'celebration', emoji: '\uD83C\uDF87'),
];

/// Categories with display labels for filter chips.
const kStickerCategories = [
  {'value': 'all', 'label': 'All'},
  {'value': 'emotions', 'label': 'Emotions'},
  {'value': 'shapes', 'label': 'Shapes'},
  {'value': 'symbols', 'label': 'Symbols'},
  {'value': 'nature', 'label': 'Nature'},
  {'value': 'arabic', 'label': 'Arabic'},
  {'value': 'social', 'label': 'Social'},
  {'value': 'celebration', 'label': 'Celebration'},
];
