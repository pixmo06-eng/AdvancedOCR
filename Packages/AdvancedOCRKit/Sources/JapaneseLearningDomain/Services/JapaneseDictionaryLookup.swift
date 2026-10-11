import Foundation

public enum JapaneseDictionaryLookup: Sendable {
    public static func lookup(word: String) -> String? {
        let clean = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }

        if let exact = dictionary[clean] {
            return exact
        }

        if let inflected = lookupInflection(clean) {
            return inflected
        }

        return lookupByComponents(clean)
    }

    private static func lookupInflection(_ word: String) -> String? {
        let politeEndings = ["ました", "ません", "ます", "たい", "ない"]
        for ending in politeEndings {
            guard word.hasSuffix(ending) else { continue }
            let base = String(word.dropLast(ending.count))
            if let def = dictionary[base + "る"] {
                return def
            }
            guard let lastChar = base.last else { continue }
            let root = String(base.dropLast())
            let godanMap: [Character: String] = [
                "い": "う", "き": "く", "ぎ": "ぐ", "し": "す",
                "ち": "つ", "に": "ぬ", "ひ": "ふ", "び": "ぶ",
                "み": "む", "り": "る"
            ]
            if let uChar = godanMap[lastChar], let def = dictionary[root + uChar] {
                return def
            }
            if let def = dictionary[base] {
                return def
            }
        }
        return nil
    }

    private static func lookupByComponents(_ word: String) -> String? {
        guard word.count > 1 else { return nil }
        var parts: [String] = []
        for char in word {
            let s = String(char)
            guard let def = dictionary[s] else { continue }
            parts.append(def)
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: ", ")
    }

    private static let dictionary: [String: String] = [
        // Days & Nature
        "日": "Day, Sun, Sunday", "にち": "Day, Sun, Sunday", "ひ": "Day, Sun, Fire",
        "月": "Moon, Month, Monday", "つき": "Moon, Month", "げつ": "Moon, Month",
        "火": "Fire, Tuesday", "か": "Fire, Tuesday",
        "水": "Water, Wednesday", "みず": "Water", "すい": "Water",
        "木": "Tree, Wood, Thursday", "き": "Tree, Wood", "もく": "Tree, Thursday",
        "金": "Money, Gold, Friday", "かね": "Money, Gold", "きん": "Gold, Friday",
        "土": "Earth, Soil, Saturday", "つち": "Earth, Soil", "ど": "Soil, Saturday",
        "空": "Sky, Air", "そら": "Sky",
        "天": "Heaven, Sky", "あめ": "Rain, Candy", "雨": "Rain",
        "山": "Mountain", "やま": "Mountain",
        "川": "River", "かわ": "River",
        "田": "Rice Field", "た": "Rice field",
        "林": "Woods, Grove", "はやし": "Woods",
        "森": "Forest", "もり": "Forest",
        "石": "Stone, Rock", "いし": "Stone",
        "花": "Flower", "はな": "Flower, Nose",
        "草": "Grass", "くさ": "Grass",
        "竹": "Bamboo", "たけ": "Bamboo",

        // Living things
        "人": "Person, People", "ひと": "Person",
        "子": "Child", "こ": "Child", "こども": "Children",
        "男": "Man, Male", "おとこ": "Man, Male",
        "女": "Woman, Female", "おんな": "Woman, Female",
        "犬": "Dog", "いぬ": "Dog",
        "猫": "Cat", "ねこ": "Cat",
        "鳥": "Bird", "とり": "Bird",
        "魚": "Fish", "さかな": "Fish",
        "虫": "Insect, Bug", "むし": "Insect, Bug",

        // Body parts
        "目": "Eye", "め": "Eye",
        "耳": "Ear", "みみ": "Ear",
        "口": "Mouth", "くち": "Mouth",
        "手": "Hand", "て": "Hand",
        "足": "Foot, Leg", "あし": "Foot, Leg",
        "力": "Power, Strength", "ちから": "Power",

        // Numbers & Time
        "一": "One", "いち": "One", "ひとつ": "One item",
        "二": "Two", "に": "Two", "ふたつ": "Two items",
        "三": "Three", "さん": "Three", "みっつ": "Three items",
        "四": "Four", "よん": "Four", "し": "Four", "よっつ": "Four items",
        "五": "Five", "ご": "Five", "いつつ": "Five items",
        "六": "Six", "ろく": "Six", "むっつ": "Six items",
        "七": "Seven", "なな": "Seven", "しち": "Seven", "ななつ": "Seven items",
        "八": "Eight", "はち": "Eight", "やっつ": "Eight items",
        "九": "Nine", "きゅう": "Nine", "く": "Nine", "ここのつ": "Nine items",
        "十": "Ten", "じゅう": "Ten", "とお": "Ten items",
        "百": "Hundred", "ひゃく": "Hundred",
        "千": "Thousand", "せん": "Thousand",
        "万": "Ten Thousand", "まん": "Ten thousand",
        "円": "Yen, Circle", "えん": "Yen",
        "年": "Year", "とし": "Year", "ねん": "Year",
        "時": "Time, Hour, When", "とき": "Time, When",
        "分": "Minute, Part", "ふん": "Minute",
        "半": "Half", "はん": "Half",
        "今": "Now", "いま": "Now", "こん": "This / Present",
        "今日": "Today", "きょう": "Today",
        "明日": "Tomorrow", "あした": "Tomorrow",
        "昨日": "Yesterday", "きのう": "Yesterday",
        "毎日": "Every day", "まいにち": "Every day",
        "朝": "Morning", "あさ": "Morning",
        "昼": "Noon, Daytime", "ひる": "Noon",
        "夜": "Night, Evening", "よる": "Night",
        "夕方": "Evening", "ゆうがた": "Evening",
        "春": "Spring", "はる": "Spring",
        "夏": "Summer", "なつ": "Summer",
        "秋": "Autumn, Fall", "あき": "Autumn",
        "冬": "Winter", "ふゆ": "Winter",

        // Positions & Colors
        "上": "Up, Above, Top", "うえ": "Up, Above",
        "下": "Down, Below, Under", "した": "Down, Below",
        "左": "Left", "ひだり": "Left",
        "右": "Right", "みぎ": "Right",
        "中": "Inside, Middle", "なか": "Inside, Middle",
        "前": "Front, Before", "まえ": "Front, Before",
        "後": "Behind, After", "うしろ": "Behind", "あと": "After",
        "大": "Big, Large", "おおきい": "Big, Large", "大きい": "Big, Large",
        "小": "Small, Little", "ちいさい": "Small, Little", "小さい": "Small, Little",
        "白": "White", "しろ": "White", "しろい": "White", "白い": "White",
        "赤": "Red", "あか": "Red", "あかい": "Red", "赤い": "Red",
        "青": "Blue", "あお": "Blue", "あおい": "Blue", "青い": "Blue",
        "黒": "Black", "くろ": "Black", "くろい": "Black", "黒い": "Black",

        // School, Life & Actions
        "本": "Book, Origin", "ほん": "Book",
        "文": "Sentence, Writing", "ぶん": "Sentence, Part",
        "字": "Character, Letter", "じ": "Letter, Kanji, O'clock",
        "学": "Study, Learning", "がく": "Study", "まなぶ": "To study",
        "校": "School", "こう": "School", "学校": "School", "がっこう": "School",
        "先生": "Teacher", "せんせい": "Teacher",
        "学生": "Student", "がくせい": "Student",
        "名前": "Name", "なまえ": "Name",
        "車": "Car, Vehicle", "くるま": "Car",
        "道": "Road, Way, Street", "みち": "Road, Way",
        "町": "Town, Street", "まち": "Town",
        "家": "House, Home", "いえ": "House, Home", "うち": "Home",
        "店": "Shop, Store", "みせ": "Shop, Store",
        "友": "Friend", "ともだち": "Friend", "友達": "Friend",
        "見る": "To see, watch, look", "みる": "To see, look",
        "聞く": "To hear, listen, ask", "きく": "To hear, listen",
        "言う": "To say", "いう": "To say",
        "話す": "To speak, talk", "はなす": "To speak, talk",
        "読む": "To read", "よむ": "To read",
        "書く": "To write, draw", "かく": "To write, draw",
        "食べる": "To eat", "たべる": "To eat",
        "飲む": "To drink", "のむ": "To drink",
        "行く": "To go", "いく": "To go",
        "来る": "To come", "くる": "To come",
        "帰る": "To return home", "かえる": "To return home",
        "出る": "To exit, leave", "でる": "To exit, leave",
        "入る": "To enter", "はいる": "To enter",
        "立つ": "To stand", "たつ": "To stand",
        "休む": "To rest", "やすむ": "To rest",
        "会う": "To meet", "あう": "To meet",
        "使う": "To use", "つかう": "To use",
        "何": "What", "なに": "What", "なん": "What"
    ]
}
