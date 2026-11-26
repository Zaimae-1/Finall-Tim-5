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

const lessons = [
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
