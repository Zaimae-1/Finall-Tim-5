enum ExerciseKind { choice, order, match }

class Exercise {
  const Exercise.choice(this.prompt, this.options, int correct)
    : kind = ExerciseKind.choice,
      answer = const [],
      correctChoice = correct,
      words = const [];

  const Exercise.order(this.prompt, this.options, this.answer)
    : kind = ExerciseKind.order,
      correctChoice = null,
      words = const [];

  const Exercise.match(this.words, this.options, this.answer)
    : kind = ExerciseKind.match,
      prompt = 'Pasangkan kata dengan artinya.',
      correctChoice = null;

  final ExerciseKind kind;
  final String prompt;
  final List<String> options;
  final List<String> words;
  final List<int> answer;
  final int? correctChoice;

  String get solution => switch (kind) {
    ExerciseKind.choice => options[correctChoice!],
    ExerciseKind.order => answer.map((index) => options[index]).join(' '),
    ExerciseKind.match => List.generate(
      words.length,
      (index) => '${words[index]} = ${options[answer[index]]}',
    ).join(' · '),
  };
}

class Lesson {
  const Lesson(this.id, this.title, this.description, this.exercises);

  final String id;
  final String title;
  final String description;
  final List<Exercise> exercises;
}

bool isTreasureLevel(int level) => level > 0 && level % 5 == 0;

final List<Lesson> lessons = List.unmodifiable([
  ..._starterLessons,
  for (var level = 6; level <= 100; level++) _makeLesson(level),
]);

const _starterLessons = [
  Lesson('greetings', 'Sapa seseorang', 'Sapaan dan ucapan sehari-hari', [
    Exercise.choice('Apa arti “Good morning”?', [
      'Selamat malam',
      'Selamat pagi',
      'Sampai jumpa',
    ], 1),
    Exercise.order(
      'Susun terjemahan “Apa kabar?”',
      ['you', 'How', 'fine', 'are'],
      [1, 3, 0],
    ),
    Exercise.match(
      ['Hello', 'Thanks', 'Goodbye'],
      ['Terima kasih', 'Sampai jumpa', 'Halo'],
      [2, 0, 1],
    ),
    Exercise.choice('Pilih sapaan yang sopan saat bertemu.', [
      'See you tomorrow',
      'Nice to meet you',
      'Good night',
    ], 1),
    Exercise.order(
      'Susun terjemahan “Sampai jumpa besok.”',
      ['tomorrow', 'you', 'See', 'morning'],
      [2, 1, 0],
    ),
  ]),
  Lesson('intro', 'Perkenalkan diri', 'Nama, asal, dan salam kenal', [
    Exercise.order(
      'Susun terjemahan “Namaku Nara.”',
      ['Nara', 'is', 'My', 'name'],
      [2, 3, 1, 0],
    ),
    Exercise.choice('Apa arti “Where are you from?”', [
      'Di mana rumahmu?',
      'Siapa namamu?',
      'Kamu berasal dari mana?',
    ], 2),
    Exercise.match(['Name', 'Friend', 'Student'], ['Teman', 'Nama', 'Siswa'], [
      1,
      0,
      2,
    ]),
    Exercise.choice('Lengkapi “I ___ a student.”', ['am', 'is', 'are'], 0),
    Exercise.order(
      'Susun terjemahan “Aku dari Indonesia.”',
      ['Indonesia', 'from', 'am', 'I'],
      [3, 2, 1, 0],
    ),
  ]),
  Lesson('ordering', 'Pesan makanan', 'Meminta makanan dan minuman', [
    Exercise.choice('Apa arti “I would like some water”?', [
      'Aku ingin air putih',
      'Aku ingin jus',
      'Aku suka makan roti',
    ], 0),
    Exercise.match(['Bread', 'Water', 'Rice'], ['Nasi', 'Roti', 'Air'], [
      1,
      2,
      0,
    ]),
    Exercise.order(
      'Susun terjemahan “Teh, tolong.”',
      ['please', 'Tea', 'rice'],
      [1, 0],
    ),
    Exercise.choice('Pilih cara bertanya harga dengan sopan.', [
      'Can I sit here?',
      'How much is it?',
      'What is your name?',
    ], 1),
    Exercise.order(
      'Susun terjemahan “Aku ingin nasi.”',
      ['rice', 'I', 'like', 'would'],
      [1, 3, 2, 0],
    ),
  ]),
  Lesson('directions', 'Cari arah', 'Menemukan jalan di kota', [
    Exercise.choice('Apa arti “Turn left”?', [
      'Belok kiri',
      'Belok kanan',
      'Jalan lurus',
    ], 0),
    Exercise.order(
      'Susun “Di mana stasiunnya?”',
      ['the', 'Where', 'station', 'is'],
      [1, 3, 0, 2],
    ),
    Exercise.match(['Left', 'Right', 'Straight'], ['Lurus', 'Kiri', 'Kanan'], [
      1,
      2,
      0,
    ]),
    Exercise.choice('Apa arti “Go straight”?', [
      'Berhenti',
      'Jalan lurus',
      'Naik kapal',
    ], 1),
    Exercise.order('Susun “Belok kanan.”', ['right', 'Turn', 'left'], [1, 0]),
  ]),
  Lesson(
    'treasure',
    'Pulau harta karun',
    'Ulangi kosakata dan buka peti bonus',
    [
      Exercise.choice('Apa arti “Treasure”?', [
        'Perjalanan',
        'Harta karun',
        'Pulau',
      ], 1),
      Exercise.match(['Island', 'Boat', 'Map'], ['Peta', 'Pulau', 'Kapal'], [
        1,
        2,
        0,
      ]),
      Exercise.order(
        'Susun “Temukan pulau itu.”',
        ['island', 'Find', 'the', 'boat'],
        [1, 2, 0],
      ),
      Exercise.choice('Apa arti “Open the chest”?', [
        'Buka peti',
        'Tutup pintu',
        'Cari peta',
      ], 0),
      Exercise.order(
        'Susun “Ini harta karunku.”',
        ['treasure', 'This', 'my', 'is'],
        [1, 3, 2, 0],
      ),
    ],
  ),
];

typedef _Topic = ({String title, List<String> english, List<String> indonesia});

const List<_Topic> _topics = [
  (
    title: 'Di rumah',
    english: ['House', 'Door', 'Window', 'Kitchen', 'Bedroom'],
    indonesia: ['Rumah', 'Pintu', 'Jendela', 'Dapur', 'Kamar tidur'],
  ),
  (
    title: 'Di sekolah',
    english: ['School', 'Teacher', 'Book', 'Pencil', 'Classroom'],
    indonesia: ['Sekolah', 'Guru', 'Buku', 'Pensil', 'Ruang kelas'],
  ),
  (
    title: 'Di pantai',
    english: ['Beach', 'Sand', 'Wave', 'Shell', 'Sea'],
    indonesia: ['Pantai', 'Pasir', 'Ombak', 'Kerang', 'Laut'],
  ),
  (
    title: 'Warna',
    english: ['Blue', 'Red', 'Green', 'Yellow', 'White'],
    indonesia: ['Biru', 'Merah', 'Hijau', 'Kuning', 'Putih'],
  ),
  (
    title: 'Keluarga',
    english: ['Mother', 'Father', 'Sister', 'Brother', 'Grandmother'],
    indonesia: ['Ibu', 'Ayah', 'Saudari', 'Saudara laki-laki', 'Nenek'],
  ),
  (
    title: 'Hewan',
    english: ['Shark', 'Dolphin', 'Turtle', 'Bird', 'Cat'],
    indonesia: ['Hiu', 'Lumba-lumba', 'Penyu', 'Burung', 'Kucing'],
  ),
  (
    title: 'Buah',
    english: ['Apple', 'Banana', 'Orange', 'Mango', 'Grape'],
    indonesia: ['Apel', 'Pisang', 'Jeruk', 'Mangga', 'Anggur'],
  ),
  (
    title: 'Waktu',
    english: ['Morning', 'Noon', 'Evening', 'Night', 'Today'],
    indonesia: ['Pagi', 'Siang', 'Sore', 'Malam', 'Hari ini'],
  ),
  (
    title: 'Pakaian',
    english: ['Shirt', 'Shoes', 'Hat', 'Jacket', 'Dress'],
    indonesia: ['Kemeja', 'Sepatu', 'Topi', 'Jaket', 'Gaun'],
  ),
  (
    title: 'Transportasi',
    english: ['Bus', 'Train', 'Bicycle', 'Airplane', 'Ship'],
    indonesia: ['Bus', 'Kereta', 'Sepeda', 'Pesawat', 'Kapal'],
  ),
  (
    title: 'Di kota',
    english: ['Street', 'Market', 'Hospital', 'Park', 'Bridge'],
    indonesia: ['Jalan', 'Pasar', 'Rumah sakit', 'Taman', 'Jembatan'],
  ),
  (
    title: 'Cuaca',
    english: ['Rain', 'Sun', 'Cloud', 'Wind', 'Storm'],
    indonesia: ['Hujan', 'Matahari', 'Awan', 'Angin', 'Badai'],
  ),
  (
    title: 'Tubuh',
    english: ['Head', 'Hand', 'Eye', 'Foot', 'Ear'],
    indonesia: ['Kepala', 'Tangan', 'Mata', 'Kaki', 'Telinga'],
  ),
  (
    title: 'Kegiatan',
    english: ['Read', 'Write', 'Swim', 'Sleep', 'Run'],
    indonesia: ['Membaca', 'Menulis', 'Berenang', 'Tidur', 'Berlari'],
  ),
  (
    title: 'Perasaan',
    english: ['Happy', 'Sad', 'Tired', 'Excited', 'Calm'],
    indonesia: ['Senang', 'Sedih', 'Lelah', 'Bersemangat', 'Tenang'],
  ),
  (
    title: 'Makanan',
    english: ['Fish', 'Soup', 'Egg', 'Cheese', 'Cake'],
    indonesia: ['Ikan', 'Sup', 'Telur', 'Keju', 'Kue'],
  ),
  (
    title: 'Minuman',
    english: ['Water', 'Milk', 'Tea', 'Coffee', 'Juice'],
    indonesia: ['Air', 'Susu', 'Teh', 'Kopi', 'Jus'],
  ),
  (
    title: 'Alam',
    english: ['Mountain', 'River', 'Forest', 'Island', 'Sky'],
    indonesia: ['Gunung', 'Sungai', 'Hutan', 'Pulau', 'Langit'],
  ),
  (
    title: 'Belanja',
    english: ['Price', 'Money', 'Bag', 'Receipt', 'Store'],
    indonesia: ['Harga', 'Uang', 'Tas', 'Struk', 'Toko'],
  ),
  (
    title: 'Petualangan',
    english: ['Treasure', 'Compass', 'Captain', 'Journey', 'Harbor'],
    indonesia: ['Harta karun', 'Kompas', 'Kapten', 'Perjalanan', 'Pelabuhan'],
  ),
];

Lesson _makeLesson(int level) {
  final topic = _topics[(level - 6) % _topics.length];
  final shift = (level - 6) ~/ _topics.length;
  final exercises = <Exercise>[
    for (var question = 0; question < 4; question++)
      _wordChoice(topic, (shift + question) % 5, level + question),
    Exercise.match(
      [
        for (var index = 0; index < 3; index++)
          topic.english[(shift + index) % 5],
      ],
      [
        topic.indonesia[(shift + 1) % 5],
        topic.indonesia[(shift + 2) % 5],
        topic.indonesia[shift % 5],
      ],
      const [2, 0, 1],
    ),
  ];
  return Lesson(
    'level_$level',
    isTreasureLevel(level)
        ? 'Pulau harta karun $level'
        : '${topic.title} $level',
    isTreasureLevel(level)
        ? 'Quest Treasure · ${topic.title}'
        : 'Kosakata ${topic.title.toLowerCase()}',
    exercises,
  );
}

Exercise _wordChoice(_Topic topic, int word, int seed) {
  final correct = seed % 3;
  final options = List<String>.filled(3, '');
  options[correct] = topic.indonesia[word];
  options[(correct + 1) % 3] = topic.indonesia[(word + 1) % 5];
  options[(correct + 2) % 3] = topic.indonesia[(word + 2) % 5];
  return Exercise.choice(
    'Apa arti “${topic.english[word]}”?',
    options,
    correct,
  );
}
