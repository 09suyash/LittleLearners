import 'package:flutter/material.dart';

class StoryPage {
  final String scene;
  final String text;
  const StoryPage({required this.scene, required this.text});
}

class StoryVersion {
  final String title;
  final String tag;
  final List<StoryPage> pages;
  final String moral;
  const StoryVersion({
    required this.title,
    required this.tag,
    required this.pages,
    required this.moral,
  });
}

class StoryData {
  final int id;
  final String icon;
  final Color color;
  final StoryVersion en;
  final StoryVersion hi;
  const StoryData({
    required this.id,
    required this.icon,
    required this.color,
    required this.en,
    required this.hi,
  });

  StoryVersion forLang(String lang) => lang == 'hi' ? hi : en;
}

const List<StoryData> stories = [
  StoryData(
    id: 0, icon: '🦁🐭', color: Color(0xFFc4855a),
    en: StoryVersion(
      title: 'The Lion and the Mouse', tag: 'Kindness always comes back',
      pages: [
        StoryPage(scene: '🦁😴🌿', text: 'Deep in the jungle, a mighty lion lay fast asleep under a shady tree. Golden sunlight filtered through the leaves, and the whole forest was peaceful and still.'),
        StoryPage(scene: '🐭😨🦁', text: 'A tiny mouse was scampering nearby when she accidentally ran right across the lion\'s nose, waking him with a thunderous roar! The lion grabbed her in his enormous paw.'),
        StoryPage(scene: '🐭🙏✨', text: '"Please spare me, great king!" squeaked the mouse. "Let me go, and one day I will surely help you!" The lion laughed — how could such a tiny creature ever help him? But kindly, he let her go.'),
        StoryPage(scene: '🦁🕸️😰', text: 'Days later, hunters set a strong rope net as a trap. The lion walked right into it and was caught! He roared and struggled with all his might, but could not break free.'),
        StoryPage(scene: '🐭✂️🦁🎉', text: 'The little mouse heard his desperate roar and ran to him at once. Using her sharp little teeth, she chewed through the ropes one by one — and set the great lion free! Even the smallest friend can do the mightiest deed.'),
      ],
      moral: 'No act of kindness is ever too small. Even the tiniest person can help the mightiest one. Always be kind.',
    ),
    hi: StoryVersion(
      title: 'शेर और चूहा', tag: 'दयालुता हमेशा लौटकर आती है',
      pages: [
        StoryPage(scene: '🦁😴🌿', text: 'एक घने जंगल में एक ताकतवर शेर एक बड़े पेड़ की छाँव में गहरी नींद में सो रहा था। सुनहरी धूप पत्तियों के बीच से छन रही थी और पूरा जंगल शांत था।'),
        StoryPage(scene: '🐭😨🦁', text: 'एक नन्हा चूहा इधर-उधर भागते-भागते अचानक शेर की नाक पर से गुज़र गया! शेर एक ज़ोरदार दहाड़ के साथ जागा और उसने चूहे को अपने विशाल पंजे में दबोच लिया।'),
        StoryPage(scene: '🐭🙏✨', text: '"महाराज, कृपया मुझे माफ़ कर दीजिए!" चूहे ने गिड़गिड़ाते हुए कहा। "मुझे छोड़ दीजिए, एक दिन मैं ज़रूर आपके काम आऊँगा!" शेर ज़ोर से हँसा — पर फिर भी उसने चूहे को छोड़ दिया।'),
        StoryPage(scene: '🦁🕸️😰', text: 'कुछ दिन बाद शिकारियों ने मज़बूत रस्सियों का जाल बिछाया। शेर उस जाल में फँस गया! वह दहाड़ता और छटपटाता रहा, पर जाल से निकल नहीं सका।'),
        StoryPage(scene: '🐭✂️🦁🎉', text: 'नन्हे चूहे ने शेर की बेबस दहाड़ सुनी और दौड़ा चला आया। उसने अपने नुकीले दाँतों से एक-एक रस्सी काटी — और शेर आज़ाद हो गया! छोटे दोस्त भी बड़े काम करते हैं।'),
      ],
      moral: 'दयालुता का कोई काम कभी छोटा नहीं होता। सबसे छोटा व्यक्ति भी सबसे बड़े की मदद कर सकता है। हमेशा दयालु रहो।',
    ),
  ),
  StoryData(
    id: 1, icon: '🐢🐇', color: Color(0xFF4CAF50),
    en: StoryVersion(
      title: 'The Tortoise and the Hare', tag: 'Slow and steady wins the race',
      pages: [
        StoryPage(scene: '🐇😏🐢', text: 'A boastful hare met a slow tortoise on the forest path one morning. "Look how slowly you walk!" laughed the hare. "I could beat you in any race without even trying!"'),
        StoryPage(scene: '🏁🐢🐇', text: '"Let us race then," said the tortoise calmly. All the animals gathered to watch. The signal was given — the hare shot off like lightning while the tortoise began his slow, steady walk.'),
        StoryPage(scene: '🌳😴🐇💤', text: 'The hare raced so far ahead that he could not even see the tortoise. "This is far too easy," he yawned. "I shall nap under this shady tree." And he fell fast asleep.'),
        StoryPage(scene: '🐢💪🚶', text: 'The tortoise walked on. One slow step, then another. He never stopped, never rushed, and never looked back. Steadily he moved toward the finish line.'),
        StoryPage(scene: '🎉🐢🏆🐇😲', text: 'The hare woke with a start and sprinted to the finish — but the tortoise was already there, smiling! All the animals cheered wildly. The slow, steady tortoise had won the race!'),
      ],
      moral: 'Slow and steady wins the race. Patience and perseverance always beat speed and overconfidence.',
    ),
    hi: StoryVersion(
      title: 'कछुआ और खरगोश', tag: 'धीरे और स्थिर आगे बढ़ो',
      pages: [
        StoryPage(scene: '🐇😏🐢', text: 'एक सुबह जंगल के रास्ते पर एक घमंडी खरगोश एक धीमे कछुए से मिला। "देखो तुम कितना धीमा चलते हो!" खरगोश हँसा। "मैं बिना कोशिश किए भी तुम्हें हरा सकता हूँ!"'),
        StoryPage(scene: '🏁🐢🐇', text: '"तो फिर दौड़ लगाते हैं," कछुए ने शांति से कहा। सभी जानवर देखने आ गए। संकेत मिलते ही खरगोश बिजली की तरह निकल गया और कछुआ अपनी धीमी चाल से चलने लगा।'),
        StoryPage(scene: '🌳😴🐇💤', text: 'खरगोश इतनी तेज़ी से आगे निकल गया कि कछुआ दिखाई भी नहीं दे रहा था। "यह बहुत आसान है," उसने जम्हाई ली। "इस छायादार पेड़ के नीचे थोड़ी झपकी ले लेता हूँ।" और वह गहरी नींद में सो गया।'),
        StoryPage(scene: '🐢💪🚶', text: 'कछुआ चलता रहा। एक धीमा कदम, फिर दूसरा। वह न रुका, न घबराया, न पीछे मुड़ा। कदम-दर-कदम वह आगे बढ़ता रहा।'),
        StoryPage(scene: '🎉🐢🏆🐇😲', text: 'खरगोश अचानक उठा और दौड़ा — लेकिन कछुआ पहले से ही वहाँ मुस्कुरा रहा था! सभी जानवर खुशी से चिल्लाए। धीमे और स्थिर कछुए ने दौड़ जीत ली!'),
      ],
      moral: 'धीरे और स्थिर आगे बढ़ने से जीत मिलती है। धैर्य और लगन हमेशा घमंड और जल्दबाज़ी को हराते हैं।',
    ),
  ),
  StoryData(
    id: 2, icon: '🦊🍇', color: Color(0xFF9C27B0),
    en: StoryVersion(
      title: 'The Fox and the Grapes', tag: "Don't make excuses for failure",
      pages: [
        StoryPage(scene: '🦊😋☀️', text: 'On a hot afternoon, a hungry fox wandered through a lush vineyard. He had not eaten all day and his stomach growled as the warm sun beat down on the dusty path.'),
        StoryPage(scene: '🦊🍇✨', text: 'High on a vine, he spotted a gorgeous bunch of plump, dark purple grapes glistening in the sunlight. "Those look absolutely delicious!" he exclaimed, licking his lips eagerly.'),
        StoryPage(scene: '🦊🏃💦', text: 'He leaped up as high as he could — but missed! He tried again and again. He ran, jumped, climbed a rock, and leaped from every angle. But the grapes were always just out of reach.'),
        StoryPage(scene: '🦊🚶😤', text: 'Finally, exhausted and burning with embarrassment, the fox turned away. He held his nose high in the air and walked off with as much dignity as he could manage.'),
        StoryPage(scene: '🦊💭😔', text: '"Those grapes are probably sour and tasteless anyway," he muttered to himself. But deep in his heart, he knew the truth — the grapes were perfect. He had simply failed to reach them.'),
      ],
      moral: "Don't make excuses for your failures. Admit them honestly, learn from them, and try again.",
    ),
    hi: StoryVersion(
      title: 'लोमड़ी और अंगूर', tag: 'असफलता के बहाने मत बनाओ',
      pages: [
        StoryPage(scene: '🦊😋☀️', text: 'एक गर्म दोपहर को एक भूखी लोमड़ी कुछ खाने की तलाश में अंगूर के बाग में घूम रही थी। उसने पूरा दिन कुछ नहीं खाया था और धूप में चलते-चलते उसका पेट ज़ोर-ज़ोर से बोल रहा था।'),
        StoryPage(scene: '🦊🍇✨', text: 'बेल पर ऊँचाई पर उसे पके, काले-बैंगनी अंगूरों का एक चमकीला गुच्छा दिखा। "वाह, ये तो बहुत स्वादिष्ट लग रहे हैं!" उसने होंठ चाटते हुए कहा।'),
        StoryPage(scene: '🦊🏃💦', text: 'वह जितनी ऊँची कूद सकती थी, कूदी — पर अंगूर नहीं मिले! उसने बार-बार कोशिश की। दौड़ी, कूदी, पत्थर पर चढ़ी, हर तरफ से उछली। पर अंगूर हमेशा थोड़े दूर रहे।'),
        StoryPage(scene: '🦊🚶😤', text: 'आखिरकार, थकी और शर्मिंदा होकर, लोमड़ी वहाँ से चली गई। उसने नाक ऊँची कर ली और जितनी गरिमा से हो सके, वहाँ से निकल गई।'),
        StoryPage(scene: '🦊💭😔', text: '"वैसे वो अंगूर खट्टे और बेकार ही होंगे," उसने मन में कहा। पर मन की गहराई में वह जानती थी — अंगूर बिल्कुल अच्छे थे। वह बस उन तक पहुँच नहीं पाई थी।'),
      ],
      moral: 'अपनी असफलताओं के बहाने मत बनाओ। उन्हें ईमानदारी से स्वीकारो, उनसे सीखो और फिर कोशिश करो।',
    ),
  ),
  StoryData(
    id: 3, icon: '🦅🏺', color: Color(0xFF2196F3),
    en: StoryVersion(
      title: 'The Crow and the Pitcher', tag: 'Use your brain to solve problems',
      pages: [
        StoryPage(scene: '🦅☀️😰', text: 'On a scorching summer day, a very thirsty crow flew across the dry land searching desperately for water. He had been flying for a long time and his throat was painfully parched.'),
        StoryPage(scene: '🦅🏺💧', text: 'At last, he spotted a tall clay pitcher on the ground! He flew down and peered inside — there was water. But it sat very low, far too deep for his beak to reach. He pushed the pitcher but it was too heavy.'),
        StoryPage(scene: '🦅🪨💡', text: 'The crow did not give up. He sat quietly and thought. He looked around and saw small pebbles scattered on the ground. Suddenly, a brilliant idea flashed in his clever mind!'),
        StoryPage(scene: '🦅🪨🏺', text: 'One by one, the clever crow picked up pebbles and dropped them carefully into the pitcher. With each stone, he watched the water level rise just a little higher. He worked patiently and steadily.'),
        StoryPage(scene: '🦅💧😄', text: 'After many pebbles, the water rose all the way to the brim! The crow drank deeply and felt gloriously refreshed. He had solved his problem entirely with patience and clever thinking.'),
      ],
      moral: "Where there's a will, there's a way. Use your mind and patience to solve any problem you face.",
    ),
    hi: StoryVersion(
      title: 'कौआ और घड़ा', tag: 'बुद्धि से हर समस्या हल होती है',
      pages: [
        StoryPage(scene: '🦅☀️😰', text: 'एक तपती गर्मी के दिन एक बहुत प्यासा कौआ पानी की तलाश में सूखी धरती पर उड़ रहा था। वह बहुत देर से उड़ रहा था और उसका गला बुरी तरह सूख गया था।'),
        StoryPage(scene: '🦅🏺💧', text: 'आखिरकार उसे ज़मीन पर एक लंबा मिट्टी का घड़ा दिखा! वह उतरा और झाँका — पानी था। लेकिन यह बहुत नीचे था, उसकी चोंच के पहुँचने से बहुत गहरा। घड़ा धकेला तो वह बहुत भारी निकला।'),
        StoryPage(scene: '🦅🪨💡', text: 'कौए ने हार नहीं मानी। वह शांति से बैठकर सोचने लगा। उसने आसपास देखा और पास में छोटे-छोटे कंकड़ नज़र आए। अचानक उसके मन में एक शानदार विचार आया!'),
        StoryPage(scene: '🦅🪨🏺', text: 'चतुर कौए ने एक-एक करके कंकड़ उठाए और घड़े में डालते गया। हर पत्थर के साथ उसने देखा कि पानी थोड़ा-थोड़ा ऊपर आता जा रहा है। वह धैर्य से काम करता रहा।'),
        StoryPage(scene: '🦅💧😄', text: 'बहुत सारे कंकड़ डालने के बाद पानी ऊपर तक आ गया! कौए ने भरपूर पानी पिया और तरोताज़ा हो गया। उसने धैर्य और चतुराई से अपनी समस्या हल कर ली।'),
      ],
      moral: 'जहाँ चाह, वहाँ राह। धैर्य और बुद्धि से हर समस्या का हल निकाला जा सकता है।',
    ),
  ),
  StoryData(
    id: 4, icon: '🐜🦗', color: Color(0xFFFF9800),
    en: StoryVersion(
      title: 'The Ant and the Grasshopper', tag: 'Work today, enjoy tomorrow',
      pages: [
        StoryPage(scene: '🐜☀️🌾', text: 'All through the warm, sunny summer, a tiny ant worked hard every single day. She collected seeds and grain and carried them steadily to her cozy underground home, preparing for winter.'),
        StoryPage(scene: '🦗🎵😎', text: 'Nearby, a carefree grasshopper danced and played his fiddle all day long. "Come and play with me!" he called to the ant. "Why work so hard on such a beautiful summer day?"'),
        StoryPage(scene: '🐜💪🏡', text: '"Winter is coming," said the ant without stopping. "I must prepare now." The grasshopper laughed. "Winter is far away — there is plenty of time for work later!" And he kept singing merrily.'),
        StoryPage(scene: '❄️🥶🦗', text: 'When winter arrived, the land was buried under thick white snow and the cold wind howled. The grasshopper had no food and no shelter. Shivering and hungry, he knocked on the ant\'s door.'),
        StoryPage(scene: '🐜🏠🍞🦗', text: 'The kind ant opened her door and shared some of her food. "Next summer," she said gently, "work a little every day. Then you will never go hungry in winter again." The grasshopper nodded and understood.'),
      ],
      moral: 'Hard work and preparation today bring comfort and safety tomorrow. Never put off until tomorrow what you can do today.',
    ),
    hi: StoryVersion(
      title: 'चींटी और टिड्डा', tag: 'आज मेहनत करो, कल आनंद लो',
      pages: [
        StoryPage(scene: '🐜☀️🌾', text: 'पूरी गर्म और सुनहरी गर्मी के दौरान, एक छोटी सी चींटी हर दिन बिना थके काम करती रही। वह बीज और अनाज इकट्ठा करके अपने भूमिगत घर में जमा करती — सर्दी के लिए तैयारी करती।'),
        StoryPage(scene: '🦗🎵😎', text: 'पास में एक लापरवाह टिड्डा सारा दिन नाचता और वायलिन बजाता था। "मेरे साथ खेलो!" उसने चींटी को बुलाया। "ऐसे सुंदर दिन इतनी मेहनत क्यों करनी?"'),
        StoryPage(scene: '🐜💪🏡', text: '"सर्दी आने वाली है," चींटी ने बिना रुके कहा। "मुझे अभी तैयारी करनी होगी।" टिड्डा हँसा। "सर्दी तो अभी बहुत दूर है — बाद में भी काम हो जाएगा!" और वह खुशी से गाता रहा।'),
        StoryPage(scene: '❄️🥶🦗', text: 'जब सर्दी आई तो धरती मोटी सफेद बर्फ से ढक गई और ठंडी हवा सनसनाई। टिड्डे के पास न खाना था, न आश्रय। काँपता और भूखा, उसने चींटी के दरवाज़े पर दस्तक दी।'),
        StoryPage(scene: '🐜🏠🍞🦗', text: 'दयालु चींटी ने दरवाज़ा खोला और थोड़ा खाना बाँटा। "अगली गर्मियों में," उसने नरमी से कहा, "हर दिन थोड़ा-थोड़ा काम करो। फिर सर्दियों में कभी भूखे नहीं रहोगे।" टिड्डे ने सिर झुकाकर सीख ली।'),
      ],
      moral: 'आज की मेहनत और तैयारी कल का सुख और सुरक्षा लाती है। जो काम आज हो सके उसे कल पर मत टालो।',
    ),
  ),
  StoryData(
    id: 5, icon: '🐕🦴', color: Color(0xFFF44336),
    en: StoryVersion(
      title: 'The Greedy Dog', tag: 'Be thankful for what you have',
      pages: [
        StoryPage(scene: '🐕🦴😄', text: 'A lucky dog found a big, juicy bone near a butcher\'s shop. He was absolutely delighted! He picked it up firmly in his mouth and trotted off happily toward home.'),
        StoryPage(scene: '🌉🐕💧', text: 'On the way home he had to cross a narrow wooden bridge over a calm river. He walked to the middle and happened to look down at the clear water below.'),
        StoryPage(scene: '🐕😡🐕', text: 'There in the water he saw another dog staring up at him — and that dog seemed to have an even bigger, fatter bone! "I want that bone too!" he growled with jealousy. But it was only his own reflection.'),
        StoryPage(scene: '🐕😤💦🦴', text: 'Unable to resist, the greedy dog opened his mouth wide to grab the other bone — SPLASH! His own precious bone fell straight into the river and sank to the muddy bottom.'),
        StoryPage(scene: '🐕😢💭', text: 'The dog stared sadly into the water. There was no other dog, no other bone — only his own foolish reflection. By being greedy and wanting more, he had lost everything he had.'),
      ],
      moral: 'Greed leads to loss. Be grateful and content with what you have, or you may lose it all.',
    ),
    hi: StoryVersion(
      title: 'लालची कुत्ता', tag: 'जो है उसमें संतोष रखो',
      pages: [
        StoryPage(scene: '🐕🦴😄', text: 'एक भाग्यशाली कुत्ते को एक कसाई की दुकान के पास एक बड़ी, रसीली हड्डी मिली। वह बहुत खुश था! उसने हड्डी मुँह में मज़बूती से दबाई और खुशी-खुशी घर की ओर चल पड़ा।'),
        StoryPage(scene: '🌉🐕💧', text: 'घर जाते समय उसे एक शांत नदी के ऊपर एक संकरे लकड़ी के पुल से गुज़रना था। वह पुल के बीच में पहुँचा और नीचे साफ पानी में देखने लगा।'),
        StoryPage(scene: '🐕😡🐕', text: 'पानी में उसे एक और कुत्ता दिखा जो ऊपर देख रहा था — और उस कुत्ते के मुँह में एक और भी बड़ी हड्डी थी! "मुझे वो हड्डी भी चाहिए!" उसने जलन से गुर्राया। पर वह उसकी अपनी परछाईं थी।'),
        StoryPage(scene: '🐕😤💦🦴', text: 'लालच में आकर कुत्ते ने मुँह खोला दूसरी हड्डी छीनने के लिए — धड़ाम! उसकी अपनी कीमती हड्डी सीधे नदी में जा गिरी और कीचड़ में डूब गई।'),
        StoryPage(scene: '🐕😢💭', text: 'कुत्ते ने उदास होकर खाली पानी में देखा। न कोई दूसरा कुत्ता था, न दूसरी हड्डी — केवल उसकी अपनी मूर्ख परछाईं। लालच में, उसने जो था वो सब खो दिया।'),
      ],
      moral: 'लालच में नुकसान है। जो है उसमें संतोष रखो, वरना सब कुछ खो सकते हो।',
    ),
  ),
  StoryData(
    id: 6, icon: '🐺👦', color: Color(0xFF607D8B),
    en: StoryVersion(
      title: 'The Boy Who Cried Wolf', tag: 'Always tell the truth',
      pages: [
        StoryPage(scene: '👦🐑⛰️', text: 'A young shepherd boy watched over his fluffy white sheep on a peaceful hillside every day. But the job was lonely and boring, and the mischievous boy desperately wanted some excitement.'),
        StoryPage(scene: '👦📢😂', text: '"Wolf! Wolf! A wolf is attacking the sheep!" he yelled one day as a naughty joke. The alarmed villagers grabbed their tools and ran up — but there was no wolf. The boy laughed loudly at their concern.'),
        StoryPage(scene: '👦📢🙄', text: 'A few days later, he did it again. "Wolf! Wolf!" The tired villagers ran up the hill once more — and again there was no wolf. They went home grumbling, very annoyed with the lying boy.'),
        StoryPage(scene: '🐺😱👦', text: 'Then one dark evening, a real wolf crept out from the trees and circled the frightened flock, growling and snapping! "Wolf! Wolf! Please help me!" the terrified boy screamed.'),
        StoryPage(scene: '👦😢🐑', text: 'But the villagers heard him and shook their heads. "It is just that boy tricking us again," they said — and nobody came. The wolf scattered all the sheep. The boy learned the hardest lesson of his life.'),
      ],
      moral: 'Always tell the truth. A liar is not believed even when speaking the truth. Honesty is the greatest trust.',
    ),
    hi: StoryVersion(
      title: 'भेड़िया आया रे', tag: 'हमेशा सच बोलो',
      pages: [
        StoryPage(scene: '👦🐑⛰️', text: 'एक नौजवान चरवाहा लड़का रोज़ एक शांत पहाड़ी पर अपनी भेड़ों की देखभाल करता था। लेकिन काम अकेला और उबाऊ था, और शरारती लड़के को कुछ मज़ा चाहिए था।'),
        StoryPage(scene: '👦📢😂', text: 'एक दिन नटखट मज़े के लिए उसने चिल्लाया, "भेड़िया! भेड़िया! भेड़िया भेड़ों पर हमला कर रहा है!" डरे हुए गाँव वाले दौड़े — पर कोई भेड़िया नहीं था। लड़का ज़ोर से हँसा।'),
        StoryPage(scene: '👦📢🙄', text: 'कुछ दिन बाद उसने फिर यही किया। "भेड़िया! भेड़िया!" थके गाँव वाले फिर दौड़े — और फिर कोई भेड़िया नहीं था। वे गुस्से में वापस चले गए।'),
        StoryPage(scene: '🐺😱👦', text: 'फिर एक अंधेरी शाम, एक असली भेड़िया जंगल से निकल आया और भेड़ों के चारों ओर घूमने लगा, गुर्राते हुए! "भेड़िया! भेड़िया! मेरी मदद करो!" डरे हुए लड़के ने पूरी ताकत से चिल्लाया।'),
        StoryPage(scene: '👦😢🐑', text: 'पर गाँव वालों ने सिर हिला दिया। "यह वही लड़का है जो हमें फिर धोखा दे रहा है," उन्होंने कहा — और कोई नहीं आया। भेड़िया सारी भेड़ें भगा गया। लड़के ने ज़िंदगी का सबसे कड़ा सबक सीखा।'),
      ],
      moral: 'हमेशा सच बोलो। झूठे की बात कोई नहीं मानता, तब भी जब वह सच बोले। ईमानदारी सबसे बड़ा भरोसा है।',
    ),
  ),
  StoryData(
    id: 7, icon: '🪿🥚', color: Color(0xFFE6B800),
    en: StoryVersion(
      title: 'The Golden Goose', tag: 'Greed destroys what you have',
      pages: [
        StoryPage(scene: '🧑‍🌾🪿💛', text: 'A kind farmer owned a very special goose. Every single morning, without fail, she would lay one beautiful, shining golden egg. The farmer and his wife were grateful and thanked her each day.'),
        StoryPage(scene: '💰🏪😊', text: 'He sold his golden eggs in the market and slowly became wealthy. He built a fine house, ate good food, and lived comfortably. But as he grew richer, he began to grow greedier.'),
        StoryPage(scene: '🧑‍🌾🤔💭', text: '"If she lays one egg every day," he thought greedily, "she must have hundreds of golden eggs inside her! I will cut her open and get them all at once — and be the richest man in the world!"'),
        StoryPage(scene: '🪿😢🔪', text: 'With trembling hands, the foolish farmer took out his knife and cut open the goose — but found nothing inside. No gold. No eggs. Nothing at all. She was exactly like any ordinary goose.'),
        StoryPage(scene: '🧑‍🌾😭❌', text: 'The farmer sank to the ground and wept bitterly. There would be no more golden eggs — ever again. His terrible greed had destroyed the very source of all his wealth and happiness.'),
      ],
      moral: "Greed destroys what patience built. Be grateful for steady blessings — never sacrifice tomorrow's abundance for today's impatience.",
    ),
    hi: StoryVersion(
      title: 'सोने के अंडे वाली मुर्गी', tag: 'लालच अपना ही नुकसान करता है',
      pages: [
        StoryPage(scene: '🧑‍🌾🪿💛', text: 'एक दयालु किसान के पास एक बहुत खास मुर्गी थी। हर एक सुबह बिना नागा, वह एक सुंदर, चमकीला सोने का अंडा देती थी। किसान और उसकी पत्नी हर दिन उसका दिल से शुक्रिया करते थे।'),
        StoryPage(scene: '💰🏪😊', text: 'वह सोने के अंडे बाज़ार में बेचकर धीरे-धीरे अमीर हो गया। अच्छा घर बनाया, अच्छा खाना खाया और आराम से जीने लगा। लेकिन जैसे-जैसे अमीर होता गया, लालच भी बढ़ता गया।'),
        StoryPage(scene: '🧑‍🌾🤔💭', text: '"अगर वो हर रोज़ एक अंडा देती है," उसने लालच में सोचा, "तो उसके पेट में सैकड़ों सोने के अंडे होंगे! मैं उसे काट दूँगा और एक साथ सब निकाल लूँगा — और दुनिया का सबसे अमीर आदमी बन जाऊँगा!"'),
        StoryPage(scene: '🪿😢🔪', text: 'काँपते हाथों से मूर्ख किसान ने चाकू निकाला और मुर्गी काट दी — लेकिन अंदर कुछ नहीं था। न सोना, न अंडे, बिल्कुल कुछ नहीं। वह बिल्कुल आम मुर्गी जैसी थी।'),
        StoryPage(scene: '🧑‍🌾😭❌', text: 'किसान ज़मीन पर बैठ गया और फूट-फूटकर रोया। अब कभी सोने के अंडे नहीं मिलेंगे — कभी नहीं। उसके भयानक लालच ने उसकी सारी खुशी और दौलत के स्रोत को हमेशा के लिए नष्ट कर दिया।'),
      ],
      moral: 'लालच उस सब को नष्ट कर देता है जो धैर्य ने बनाया था। नियमित आशीर्वाद के लिए कृतज्ञ रहो — कभी भी आज की जल्दबाज़ी के लिए कल की समृद्धि का बलिदान मत करो।',
    ),
  ),
];
