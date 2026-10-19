"""ストア掲載文の下書きを作り、文字数の上限（タイトル30・短い説明80・長い説明4000）を検査する。
usage: python3 tools/make_store_listing.py > docs/store_listing_v0_1.md
ルール: yourwish/docs/aso-rules.md（絵文字・「無料」「ベスト」「今すぐダウンロード」をタイトル等に入れない／機能と説明を一致させる）。"""
import sys

L = {  # アプリ -> 言語 -> (タイトル, 短い説明, 長い説明)
    "terrimap_ge": {
        "en-US": (
            "State Master – Germany",
            "Learn Germany's 16 states and capitals with map quizzes and tower defense.",
            """Learn the 16 states of Germany and their capitals – and defend them.

QUIZ
• Tap the state on the map, name the highlighted state, match capitals, or guess a state from its outline.
• A daily challenge gives everyone the same questions. Share your result.
• Your progress is saved on your device, and weak spots come back for review.

BATTLE
• Defend a state capital in a tower-defense battle. The map is the shape of the real state, enemies come in from neighboring states, and your base is the capital.
• Build farms, harbors, factories, mines, castles and chapels. Every state has its own landscape, weather and local specialty buildings.
• Answer quiz questions during the battle to unlock skills and repair buildings for free. You can switch this off in settings.
• Weather such as storms, floods and heat waves changes the fight, and the seasons change as waves go by.
• Three difficulty levels: easy, normal and hard.
• Daily Battle: everyone plays the same stage each day. Watch the replay, or send a challenge code to a friend – the replay is verified, so the result can be trusted.

MORE TO PLAY
• Regional battles combine several states into one big stage.
• Extra stages are inspired by German legends such as the Loreley, the Grimm fairy tales and the Nibelungenlied. Each one explains what is real and what is legend.

TRACK YOUR PROGRESS
• Daily landmark fact and a landmark quiz mode.
• Weekly accuracy graph, weak-spot ranking and adaptive quizzes that favor what you miss.
• Share card for your results, optional sound, daily reminder and a color-blind-friendly palette.

HOW IT WORKS
• Four states are free to play. A one-time purchase unlocks all 16 states and removes ads. No subscription.
• Available in several languages.

Map data: see "Data credits" in the app. This app is not affiliated with any government body.""",
        ),
        "de-DE": (
            "Bundesländer-Meister",
            "Lerne 16 Bundesländer und Hauptstädte mit Karten-Quiz und Tower-Defense.",
            """Lerne die 16 Bundesländer und ihre Hauptstädte – und verteidige sie.

QUIZ
• Tippe das Land auf der Karte an, benenne das markierte Land, ordne Hauptstädte zu oder errate ein Land an seinem Umriss.
• Die tägliche Herausforderung: Alle bekommen dieselben Fragen. Teile dein Ergebnis.
• Dein Fortschritt wird auf dem Gerät gespeichert. Schwache Stellen kommen zur Wiederholung zurück.

KAMPF
• Verteidige eine Landeshauptstadt im Tower-Defense-Kampf. Die Karte hat die Form des echten Landes, die Gegner kommen aus den Nachbarländern, deine Basis ist die Hauptstadt.
• Baue Höfe, Häfen, Fabriken, Zechen, Burgen und Kapellen. Jedes Land hat eigene Landschaft, eigenes Wetter und besondere Gebäude.
• Beantworte im Kampf Quizfragen, um Fähigkeiten freizuschalten und Gebäude kostenlos zu reparieren. In den Einstellungen abschaltbar.
• Wetter wie Sturm, Hochwasser und Hitzewelle verändert den Kampf, und die Jahreszeiten wechseln mit den Wellen.
• Drei Schwierigkeitsgrade: leicht, normal und schwer.
• Tageskampf: Alle spielen jeden Tag dieselbe Stufe. Sieh dir die Wiederholung an oder schicke einen Herausforderungscode an Freunde – die Wiederholung wird geprüft.

MEHR ZUM SPIELEN
• Regionalkämpfe verbinden mehrere Länder zu einer großen Stufe.
• Die Extra-Stufen greifen deutsche Sagen auf, etwa die Loreley, die Märchen der Brüder Grimm und das Nibelungenlied. Jede erklärt, was echt ist und was Sage.

FORTSCHRITT
• Tägliche Sehenswürdigkeit und ein Quiz-Modus dazu.
• Wochengrafik der Trefferquote, Rangliste der schwachen Stellen und adaptives Quiz, das Fehler öfter fragt.
• Teilen-Karte, optionaler Ton, tägliche Erinnerung und farbenblindengerechte Farben.

SO FUNKTIONIERT ES
• Vier Länder sind kostenlos spielbar. Ein einmaliger Kauf schaltet alle 16 Länder frei und entfernt Werbung. Kein Abo.
• In mehreren Sprachen verfügbar.

Kartendaten: siehe „Datenquellen" in der App. Diese App steht in keiner Verbindung zu staatlichen Stellen.""",
        ),
    },
    "terrimap_us": {
        "en-US": (
            "State Master – USA",
            "Learn the 50 states, D.C. and capitals with map quizzes and tower defense.",
            """Learn all 50 states plus Washington, D.C. – and defend their capitals.

QUIZ
• Tap the state on the map, name the highlighted state, match capitals, or guess a state from its outline.
• A daily challenge gives everyone the same questions. Share your result.
• Your progress is saved on your device, and weak spots come back for review.

BATTLE
• Defend a state capital in a tower-defense battle. The map is the shape of the real state, enemies come in from neighboring states, and your base is the capital.
• Build grain silos, fishing trawlers, assembly lines, oil derricks, capitol halls and town churches. Every state has its own landscape, weather and local specialty buildings.
• Answer quiz questions during the battle to unlock skills and repair buildings for free. You can switch this off in settings.
• Tornadoes, hurricanes, blizzards and more change the fight, and the seasons change as waves go by.
• Three difficulty levels: easy, normal and hard.
• Daily Battle: everyone plays the same stage each day. Watch the replay, or send a challenge code to a friend – the replay is verified, so the result can be trusted.

MORE TO PLAY
• Regional battles combine several states into one big stage: Northeast, Midwest, South and West.
• Extra stages are inspired by American tall tales and history: Paul Bunyan, the Wright brothers and the Apollo program. Each one explains what is real and what is legend.

TRACK YOUR PROGRESS
• Daily landmark fact and a landmark quiz mode.
• Weekly accuracy graph, weak-spot ranking and adaptive quizzes that favor what you miss.
• Share card for your results, optional sound, daily reminder and a color-blind-friendly palette.

HOW IT WORKS
• A few states are free to play. A one-time purchase unlocks all 51 and removes ads. No subscription.
• Available in several languages.

Map data: see "Data credits" in the app. This app is not affiliated with any government body or agency.""",
        ),
        "es-US": (
            "Maestro de Estados – EE. UU.",
            "Aprende los 50 estados y capitales con quizzes de mapas y batallas de defensa.",
            """Aprende los 50 estados y Washington, D.C. – y defiende sus capitales.

QUIZ
• Toca el estado en el mapa, nombra el estado resaltado, une capitales o adivina un estado por su silueta.
• El reto diario da a todos las mismas preguntas. Comparte tu resultado.
• Tu progreso se guarda en tu dispositivo y los puntos débiles vuelven para repasar.

BATALLA
• Defiende la capital de un estado en una batalla de defensa de torres. El mapa tiene la forma del estado real, los enemigos llegan desde los estados vecinos y tu base es la capital.
• Construye silos, barcos pesqueros, líneas de montaje, torres petroleras, capitolios e iglesias. Cada estado tiene su propio paisaje, clima y edificios especiales.
• Responde preguntas durante la batalla para desbloquear habilidades y reparar edificios gratis. Se puede desactivar en ajustes.
• Tornados, huracanes, tormentas de nieve y más cambian el combate, y las estaciones cambian con las oleadas.
• Tres niveles de dificultad: fácil, normal y difícil.
• Batalla diaria: todos juegan el mismo nivel cada día. Mira la repetición o envía un código de desafío a un amigo – la repetición se verifica, así que el resultado es fiable.

MÁS PARA JUGAR
• Las batallas regionales unen varios estados en un nivel enorme: Noreste, Medio Oeste, Sur y Oeste.
• Los niveles extra se inspiran en leyendas e historia de EE. UU.: Paul Bunyan, los hermanos Wright y el programa Apolo. Cada uno explica qué es real y qué es leyenda.

TU PROGRESO
• Dato diario de un lugar emblemático y modo de cuestionario de lugares.
• Gráfico semanal de aciertos, ranking de puntos débiles y cuestionario adaptable que repite lo que fallas.
• Tarjeta para compartir, sonido opcional, recordatorio diario y paleta para daltonismo.

CÓMO FUNCIONA
• Algunos estados son gratuitos. Una compra única desbloquea los 51 y quita los anuncios. Sin suscripción.
• Disponible en varios idiomas.

Datos del mapa: consulta «Créditos de datos» en la app. Esta app no está afiliada a ningún organismo gubernamental.""",
        ),
    },
}
LIM = (30, 80, 4000)
bad = []
out = ["# ストア掲載文 下書き v0.1", "",
       "`tools/make_store_listing.py` が作る。文字数は自動検査（タイトル30・短い説明80・長い説明4000）。**ネイティブの確認が必要**（特に de・es）。",
       "ルール: `yourwish/docs/aso-rules.md`（タイトル等に「無料」「ベスト」「今すぐ」・絵文字・全大文字を入れない／機能と説明を一致させる／実績の数字は自アプリの事実だけ）。", ""]
for app, langs in L.items():
    out += [f"## {app}", ""]
    for loc, (t, s, d) in langs.items():
        for name, txt, lim in (("タイトル", t, LIM[0]), ("短い説明", s, LIM[1]), ("長い説明", d, LIM[2])):
            if len(txt) > lim:
                bad.append(f"{app} {loc} {name}: {len(txt)} > {lim}")
        out += [f"### {loc}", "", f"**タイトル**（{len(t)}/30）: `{t}`", "", f"**短い説明**（{len(s)}/80）: {s}", "",
                f"**長い説明**（{len(d)}/4000）:", "", "```", d, "```", ""]
out += ["## 掲載前のチェック", "",
        "- [ ] 説明にある機能は、公開するバージョンに全部入っている（今日のバトル・リプレイ・地方決戦・エクストラ・クイズ連動）",
        "- [ ] エクストラの事実の注記を確認した（`docs/extra_fact_check.md` の記録欄）",
        "- [ ] 「買い切りで全州解放・広告なし」の表示が、アプリ内の購入画面と一致している",
        "- [ ] 翻訳（de・es）をネイティブが確認した。地名・州都名の綴りも",
        "- [ ] 地図データの出典表記が、アプリ内「データ出典」と一致している",
        "- [ ] 米国版: NASA・政府機関の名称/ロゴを、提携しているように見せていない（説明の末尾の注記あり）",
        "- [ ] 対象年齢・広告のデータセーフティ申告（子ども向けではない場合の設定）",
        "- [ ] Android vitals（クラッシュ率 1.09%未満・ANR率 0.47%未満）", "",
        "## スクリーンショット案（横向き。8枚まで。文字の追加はテストで効果を確かめる）", "",
        "1. バトルの盤面（州の形・施設・敵）— 「州を守る」が1枚で伝わる絵",
        "2. 地図クイズ（州をタップ）",
        "3. 州の選択（通常／地方決戦／エクストラ）",
        "4. 天候・季節が出ているバトル",
        "5. クイズでスキルを選ぶ場面",
        "6. エクストラの説明（伝説と事実の注記）",
        "7. 今日のバトルの結果（🟩🟥の共有）",
        "8. リプレイの視聴", "",
        "動画（任意）: 15〜30秒。冒頭の数秒でバトルを見せる。ミュート前提で字幕。実機映像が中心。", ""]
print("\n".join(out))
if bad:
    print("\n".join(bad), file=sys.stderr)
    sys.exit(1)
