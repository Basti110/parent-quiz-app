#!/usr/bin/env python3
"""
Firebase Question Upload Script
Uploads sample questions to Firestore for the parent quiz app.
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
import sys

# Initialize Firebase Admin SDK
def initialize_firebase():
    """Initialize Firebase with service account credentials."""
    try:
        # Try to use existing app
        app = firebase_admin.get_app()
    except ValueError:
        # Initialize new app
        # You need to download your service account key from Firebase Console
        # and save it as 'serviceAccountKey.json' in the same directory
        cred = credentials.Certificate('serviceAccountKey.json')
        app = firebase_admin.initialize_app(cred)

    return firestore.client()

# Category definitions
CATEGORIES = [
    {
        'id': 'motorik',
        'title': 'Motorik / Wachstum / Bewegung',
        'description': 'Fragen zur motorischen Entwicklung, Wachstum und Bewegung von Kindern',
        'order': 1,
        'iconName': 'directions_run',
        'isPremium': False
    },
    {
        'id': 'schwangerschaft',
        'title': 'Schwangerschaft',
        'description': 'Fragen rund um Schwangerschaft, Ernährung und Gesundheit',
        'order': 2,
        'iconName': 'pregnant_woman',
        'isPremium': False
    }
]

# Questions data
QUESTIONS = [
    # Motorik / Wachstum / Bewegung (15 questions)
    {
        'categoryId': 'motorik',
        'text': 'Was besagt Remo Largos Hauptbotschaft zur Geh-Entwicklung (Motorik)?',
        'options': [
            'Kinder, die krabbeln überspringen, sind motorisch im Vorteil.',
            'Alle gesunden Kinder sollten zwischen 12 und 14 Monaten laufen lernen.',
            'Der Zeitpunkt, zu dem ein Kind läuft, sagt nichts über seine spätere intellektuelle Entwicklung aus.',
            'Laufen ist immer gesünder, als Krabbeln.'
        ],
        'correctIndices': [2],
        'explanation': 'Remo Largo prägte den Satz: "Das Gras wächst nicht schneller, wenn man daran zieht." Seine Langzeitstudien zeigten: Die Entwicklungsspanne ist riesig. Manche gesunde Kinder laufen mit 9 Monaten, andere erst mit 20 Monaten. Beides ist völlig normal!',
        'tips': 'Hände weg! Widerstehe dem Reflex, dein Kind an beiden Händen zu nehmen und herumzuführen. Das Kind hängt in deinen Armen, statt sein eigenes Gleichgewicht zu finden. Besser: Gestalte die Umgebung sicher und lass das Kind an Möbeln entlanglaufen.',
        'sourceLabel': 'Largo, R. H. (1993/2010): Babyjahre',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Warum raten Physiotherapeuten und Entwicklungsexperten (z.B. nach Pikler) dringend davon ab, Babys passiv hinzusetzen (z.B. mit Kissen gestützt), bevor sie sich selbstständig aufsetzen können?',
        'options': [
            'Weil die Babys dadurch schlechter schlafen, da sie die sitzende Position im Schlaf suchen.',
            'Weil es die Verdauungsorgane staucht und so zu mehr Blähungen führt.',
            'Weil die Rumpfmuskulatur noch nicht bereit ist, was die Wirbelsäule belastet und wichtige motorische Lernschritte (wie das Drehen/Robben) überspringt.',
            'Weil das Kind durch die neue Perspektive überreizt wird und mehr schreit.'
        ],
        'correctIndices': [2],
        'explanation': 'Passives Sitzen belastet die noch weiche Wirbelsäule und verhindert, dass das Kind die Muskulatur trainiert, die es braucht, um in den Sitz und aus dem Sitz zu kommen.',
        'tips': 'Merke: "Lass mich liegen, bis ich sitze – das ist für den Rücken spitze!" Im Kinderwagen: Stell die Rückenlehne nur leicht schräg (ca. 45 Grad). Beim Essen: Auf dem Schoß ist sitzen erlaubt, da dein Körper den Rücken stützt.',
        'sourceLabel': 'Zukunft-Huber, B. (2010): Die ungestörte Entwicklung Ihres Babys',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Kurz bevor ein Baby eine neue Fähigkeit lernt (z.B. Krabbeln oder Sprechen), beobachten Eltern oft eine sogenannte „Regression". Warum ist das so?',
        'options': [
            'Das Kind spart Energie, um die Kalorien für das Muskelwachstum bereitzustellen (Thermik-Effekt).',
            'Das Kind ist frustriert, weil es die neue Fähigkeit noch nicht beherrscht, und gibt kurzzeitig auf.',
            'Das Gehirn baut massive neue neuronale Verknüpfungen auf (Synaptogenese). Dieser Umbauprozess sorgt für ein vorübergehendes Chaos und Unsicherheit, weshalb das Kind den „sicheren Hafen" (Eltern) sucht.',
            'Das ist ein Zeichen dafür, dass das Kind überreizt wurde und eine Entwicklungspause braucht.'
        ],
        'correctIndices': [2],
        'explanation': 'Es ist der Anlauf vor dem Sprung. Das Gehirn wird „neu verdrahtet". Wie bei einer Baustelle herrscht erst Chaos, bevor das neue Gebäude steht.',
        'tips': 'Denk an einen Pfeilbogen: Manchmal muss man zurückgezogen werden, um mit voller Kraft nach vorne zu schießen. Versuche nicht, in dieser Phase Erziehungsprobleme zu lösen. Dein Job ist jetzt nur Trösten und Sicherheit geben.',
        'sourceLabel': 'Fischer, K. W. (2008). Dynamic cycles of cognitive and brain development',
        'sourceUrl': None,
        'difficulty': 3,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Im Volksmund wird oft alles "Schub" genannt. Medizinisch unterscheidet man aber oft zwischen körperlichen Wachstumsschüben und mentalen Entwicklungssprüngen. Was ist das primäre Merkmal eines körperlichen Wachstumsschubs?',
        'options': [
            'Das Kind ist weinerlich und anhänglich.',
            'Das Kind hat deutlich mehr Hunger (Clusterfeeding) und schläft oft mehr als sonst.',
            'Das Kind lernt eine neue motorische Fähigkeit.',
            'Das Kind bekommt Zähne.'
        ],
        'correctIndices': [1],
        'explanation': 'Das Kind schläft in dieser Zeit mehr, da Wachstumshormone im Schlaf ausgeschüttet werden.',
        'tips': 'Merke: Wenn das Kind nur isst und schläft → Körper wächst. Wenn das Kind quengelig ist und schlecht schläft → Gehirn wächst (Entwicklungssprung).',
        'sourceLabel': 'Lampl, M. et al. (1992). Saltation and stasis: a model of human growth',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Die Autoren von "Oje, ich wachse" beschreiben drei klassische Symptome, an denen man erkennt, dass ein mentaler Sprung (Leap) beginnt. Welche sind das?',
        'options': [
            'Hunger, Husten, Hautausschlag.',
            'Lachen, Laufen, Lernen.',
            'Quengeligkeit, Anhänglichkeit, Schreien.',
            'Fieber, dünnerer Stuhlgang, mehr Schlaf.'
        ],
        'correctIndices': [2],
        'explanation': 'Diese Symptome validieren die Gefühle der Eltern. Wenn das Kind "unerträglich" wird, ist es meist nur ein Sprung.',
        'tips': 'Dein Baby hat den Kalender nicht gelesen! Die Zeitangaben in Büchern/Apps sind nur Durchschnittswerte. Basis für die Berechnung ist immer der ursprüngliche Stichtag (ET), da die Gehirnentwicklung schon im Bauch startet.',
        'sourceLabel': 'Van de Rijt, H., & Plooij, F. (The Wonder Weeks)',
        'sourceUrl': None,
        'difficulty': 1,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Warum raten Kinderärzte und Verbände (wie der Berufsverband der Kinder- und Jugendärzte) dringend von der Nutzung sogenannter "Gehfreis" (Baby-Walker zum Reinsetzen) ab?',
        'options': [
            'Weil die Kinder dadurch zu schnell laufen lernen und die Eltern auf die damit einhergehenden Veränderungen nicht gefasst sind.',
            'Weil sie häufig O-Beine verursachen und die Hüftgelenke dauerhaft verformen.',
            'Weil ein extrem hohes Unfallrisiko besteht und sie die motorische Entwicklung verzögern können.',
            'Weil die Wirbelsäule den zu langen aufrechten Gang noch nicht gewohnt ist und somit unmittelbar „Bandscheibenvorfälle" ausgelöst werden können.'
        ],
        'correctIndices': [2],
        'explanation': 'In Kanada sind diese Geräte seit 2004 komplett verboten. Kinder erreichen darin Geschwindigkeiten von bis zu 10 km/h, was zu schlimmen Unfällen führen kann. Zudem lernen sie ein falsches Bewegungsmuster.',
        'tips': 'Auch wenn euch ein Gehfrei geschenkt wird, raten wir dringend davon ab, diesen zu nutzen. Wir verstehen nicht, wie diese Geräte in Deutschland erlaubt sind und in Babymärkten verkauft werden.',
        'sourceLabel': 'Bundesarbeitsgemeinschaft „Mehr Sicherheit für Kinder" e.V. / American Academy of Pediatrics',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Viele Eltern sorgen sich, wenn ihr Baby das Krabbeln überspringt und direkt läuft (sogenannte "Po-Rutscher"). Was ist der aktuelle wissenschaftliche Stand zur Bedeutung des Krabbelns?',
        'options': [
            'Es ist absolut notwendig für die Rückenmuskulatur; wer nicht krabbelt, bekommt später Haltungsschäden.',
            'Es ist ein reiner Mythos, dass Krabbeln irgendeinen Vorteil hat.',
            'Das Krabbeln selbst ist kein striktes "Muss", aber die dabei ausgeführte "Überkreuzbewegung" ist wichtig, da sie die linke und rechte Gehirnhälfte vernetzt.',
            'Kinder, die nicht krabbeln, haben statistisch gesehen einen niedrigeren IQ.'
        ],
        'correctIndices': [2],
        'explanation': 'Wenn ein Kind nicht krabbelt, ist das kein Weltuntergang. Man sollte aber später Spiele fördern, bei denen die Körpermitte überkreuzt wird, um diese wichtige neuronale Verknüpfung nachzuholen.',
        'tips': 'Wenn dein Kind nicht krabbeln will: Zieh Hose und Socken aus. Nackte Haut auf dem Boden bremst am besten. Nutze Stulpen für die Beine oder Anti-Rutsch-Knieschoner. Lege Spielzeug kreisförmig um das Baby, so dass es sich strecken muss.',
        'sourceLabel': 'Ayres, A. J. (Bausteine der kindlichen Entwicklung) / Largo, R. (Babyjahre)',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Die Kinderärztin Emmi Pikler prägte die Kleinkindpädagogik maßgeblich. Was ist ihr wichtigster – oft kontraintuitiver – Grundsatz zur motorischen Entwicklung ("Freie Bewegungsentwicklung")?',
        'options': [
            'Man muss Babys täglich trainieren (z.B. an den Händen laufen lassen), damit sie die Meilensteine rechtzeitig erreichen.',
            'Das Kind wird niemals in eine Position gebracht (z.B. passiv hingesetzt), die es nicht aus eigener Kraft einnehmen und wieder verlassen kann.',
            'Babys sollten so früh wie möglich Lauflernhilfen nutzen.',
            'Eltern sollten die Bewegungen vormachen, damit das Baby durch Nachahmung lernt.'
        ],
        'correctIndices': [1],
        'explanation': 'Pikler sagt: "Lass mir Zeit." Nur Bewegungen, die das Kind selbst initiiert, sind sicher und gut für das Selbstvertrauen.',
        'tips': 'Vertraue den Fähigkeiten deines Kindes! Wenn du dein Kind immer hinsetzt, nimmst du ihm den Motor für die Entwicklung. Der Frust ist der einzige Grund, warum Babys überhaupt anfangen zu trainieren.',
        'sourceLabel': 'Pikler, E. (1988): Lasst mir Zeit',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Warum betrachten Physiotherapeuten den sogenannten "W-Sitz" (Kind sitzt zwischen den Fersen, Beine bilden ein W links und rechts) bei älteren Kleinkindern oft kritisch, wenn er die ausschließliche Sitzposition ist?',
        'options': [
            'Der Sitz kann die weiteren Entwicklungsschritte wie das Laufen einschränken.',
            'Er bietet eine sehr breite Unterstützungsfläche, erfordert aber kaum Rumpfstabilität. Wer nur so sitzt, trainiert seine Bauch- und Rückenmuskeln nicht und kann Rotationsbewegungen vermeiden.',
            'Das Gegenteil ist der Fall, Physiotherapeuten betrachten den sogenannten „Rauten-Sitz" sowie den „Schneidersitz" als kritisch.',
            'Der Sitz ist ungesund für die Hüfte und kann langfristig zu einer Hüftdysplasie führen.'
        ],
        'correctIndices': [1],
        'explanation': 'Kinder nutzen diesen Sitz oft, weil er "bequem" ist (man muss nicht balancieren). Wenn das Kind nur im W sitzt, deutet das oft auf einen schwachen Rumpf hin.',
        'tips': 'Ständiges Ermahnen nervt alle. Mach ein Spiel daraus! Wenn dein Kind ins W rutscht, sag fröhlich: "Wo sind deine Füße?". Das Kind streckt die Beine dann meist automatisch nach vorne aus.',
        'sourceLabel': 'Leitlinien der pädiatrischen Physiotherapie',
        'sourceUrl': None,
        'difficulty': 3,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Was versteht man in der Montessori-Pädagogik unter der "vorbereiteten Umgebung" im Kinderzimmer?',
        'options': [
            'Dass das Zimmer jeden Abend aufgeräumt wird, damit am nächsten Tag besser gespielt werden kann.',
            'Eine Umgebung, in der Materialien und Möbel so angepasst sind, dass das Kind sie ohne Hilfe nutzen kann.',
            'Ein Raum, der mit Matratzen ausgelegt ist und Kanten abgedeckt hat damit nichts passieren kann.',
            'Dass im Zimmer keine Gegenstände der Eltern zu finden sind.'
        ],
        'correctIndices': [1],
        'explanation': 'Der Raum ist der "dritte Erzieher". Wenn das Kind nicht an sein Spielzeug kommt, ist es unselbstständig. Liegt es im offenen Regal, kann es selbst entscheiden.',
        'tips': 'Geh auf die Knie und schau dir den Raum aus Kinderhöhe an. Komme ich an mein Spielzeug? Sehe ich in den Spiegel? Alles, was das Kind selbst erreichen kann, stärkt sein Selbstvertrauen.',
        'sourceLabel': 'Montessori-Dachverband Deutschland',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Du gehst mit deiner Tochter auf den Spielplatz. Sie trägt ein hübsches Kleidchen und Lackschuhe. Welchen statistisch nachweisbaren Effekt hat diese Kleidung auf ihr Spielverhalten?',
        'options': [
            'Sie spielt fröhlicher, weil sie sich hübscher fühlt.',
            'Sie bewegt sich weniger, klettert seltener und geht weniger Risiken ein. Die Sorge, schmutzig zu werden, das Höschen zu zeigen oder hängenzubleiben, bremst den motorischen Entdeckerdrang.',
            'Sie spielt wilder, um das Klischee zu brechen (Rebellionstheorie).',
            'Kleidung hat statistisch keinen Einfluss auf Bewegung.'
        ],
        'correctIndices': [1],
        'explanation': 'Kleidung ist nicht nur Stoff – sie ist eine "Bewegungserlaubnis". Studien zeigen: Mädchen in Röcken/Kleidern werden auf Spielplätzen häufiger ermahnt.',
        'tips': 'Deine Tochter liebt ihre Kleider? Zieh einfach eine robuste Leggings oder Radlerhose drunter. So kann sie kopfüber an der Stange hängen und klettern, ohne dass jemand was sieht.',
        'sourceLabel': 'Ronald, K. / Eliot, L. (2009): Pink Brain, Blue Brain',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Unsere Füße haben mehr Sinneszellen (Rezeptoren) als unser Rücken. Warum ist es für die Gehirnentwicklung eines Babys essenziell, so oft wie möglich barfuß zu sein?',
        'options': [
            'Damit sich das Kind „freier" fühlt.',
            'Für die Tiefenwahrnehmung.',
            'Es fördert die Gehirnentwicklung zwar nicht, aber Babys können an den Füßen nicht frieren.',
            'Damit das Kind durch die Kälte abgehärtet wird.'
        ],
        'correctIndices': [1],
        'explanation': 'Das Gehirn bekommt über die nackte Haut direktes Feedback über Bodenbeschaffenheit, Temperatur und Neigung. Socken wirken hier wie ein "Schalldämpfer".',
        'tips': 'Ein Baby erkältet sich durch Viren, nicht durch kühle Füße. Das sensorische Feedback ist die Basis für sicheres Laufenlernen. Drinnen und zum Laufenlernen sind nackte Füße immer überlegen.',
        'sourceLabel': 'Gento, E. (Kinderorthopädie) / Pikler-Ansatz',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Wann sollte man einem Kind die ersten "richtigen" Schuhe mit fester Sohle kaufen?',
        'options': [
            'Sobald es sich zum ersten Mal hinstellt, um den Knöchel zu stützen.',
            'Wenn es anfängt zu krabbeln, zum Schutz der Zehen.',
            'Erst dann, wenn das Kind frei und sicher draußen läuft.',
            'Es gibt keinen richtigen Zeitpunkt.'
        ],
        'correctIndices': [2],
        'explanation': 'Ein gesunder Fuß braucht keine Stütze, er braucht Training! Schuhe sind nur Schutz vor Scherben/Kälte, keine Laufhilfe.',
        'tips': 'Schuhe sind wie ein Gips: Die Muskeln verkümmern, wenn sie nicht arbeiten müssen. Drinnen und zum Laufenlernen sind nackte Füße oder Anti-Rutsch-Socken immer überlegen.',
        'sourceLabel': 'Deutsche Gesellschaft für Orthopädie und Unfallchirurgie (DGOU)',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Hebammen empfehlen, das Baby täglich einige Zeit komplett nackt (ohne Windel) strampeln zu lassen. Welchen Vorteil hat das – neben der Vorbeugung von Wundsein?',
        'options': [
            'Das Baby wird schneller braun.',
            'Es spart Windeln.',
            'Es fördert die Bewegungsfreiheit der Hüfte. Eine volle Windel ist ein dickes Paket, das die Beine in eine breite Position zwingt und Bewegungen erschwert.',
            'Es lernt so, schneller trocken zu werden.'
        ],
        'correctIndices': [2],
        'explanation': 'Ohne Windel entdecken Babys oft plötzlich motorische Fähigkeiten (z.B. Füße in den Mund stecken), die mit Windel schwerer waren.',
        'tips': 'Stell dir vor, du müsstest mit einem dicken Kissen zwischen den Beinen Sport machen. Ohne Windel kann das Baby seine Beine viel freier bewegen und den eigenen Körper besser spüren.',
        'sourceLabel': 'Hebammen-Empfehlungen',
        'sourceUrl': None,
        'difficulty': 1,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Dein Baby (ca. 7–9 Monate) fängt an, sich fortzubewegen. Allerdings robbt oder schiebt es sich konsequent rückwärts durch den Raum, weg vom Spielzeug. Ist das ein Grund zur Sorge?',
        'options': [
            'Ja, das deutet auf eine Orientierungsstörung hin.',
            'Ja, man sollte die Füße hinten blockieren, damit es merkt, wie es vorwärts geht.',
            'Nein, das ist physikalisch völlig logisch und normal. Die Armmuskulatur ist oft schon stärker entwickelt als die Beinmuskulatur.',
            'Das machen nur Babys, die Angst vor dem Spielzeug haben.'
        ],
        'correctIndices': [2],
        'explanation': 'Das Baby drückt sich mit den Händen vom Boden ab (starke Arme/Schultern). Da die Beine noch nicht wissen, wie man gegenhält, rutscht der ganze Körper nach hinten.',
        'tips': 'Es ist einfache Mechanik und ein Zeichen von Kraft, nicht von Schwäche! Der Vorwärtsgang kommt meist 2-3 Wochen später ganz von allein, wenn die Beine und Zehen "aufwachen".',
        'sourceLabel': 'Entwicklungsphysiologie',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },

    # Schwangerschaft (10 questions)
    {
        'categoryId': 'schwangerschaft',
        'text': 'Schwangere Frauen sollen Folsäure zu sich nehmen. Warum empfehlen Ärzte aber dringend, damit schon vor dem Absetzen der Verhütung zu beginnen?',
        'options': [
            'Um die Fruchtbarkeit zu steigern und schneller schwanger zu werden.',
            'Damit die Mutter keine schlechte Haut bekommt (Schwangerschaftsakne).',
            'Weil sich das Neuralrohr (Vorstufe von Gehirn und Rückenmark) bereits am 28. Tag nach der Empfängnis schließt. Zu diesem Zeitpunkt wissen viele Frauen noch gar nicht, dass sie schwanger sind.',
            'Weil Folsäure Übelkeit im ersten Trimester verhindert.'
        ],
        'correctIndices': [2],
        'explanation': 'Der kritischste Moment für Fehlbildungen (offener Rücken/Spina bifida) passiert oft schon in der 4. Schwangerschaftswoche. Der Speicher muss also vorher voll sein.',
        'tips': 'Viele denken, es reicht, wenn der Schwangerschaftstest positiv ist. Aber der kritischste Moment passiert oft schon vorher. Beginne mit Folsäure, sobald du die Verhütung absetzt.',
        'sourceLabel': 'Bundesinstitut für Risikobewertung (BfR) / Deutsche Gesellschaft für Ernährung',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'schwangerschaft',
        'text': 'Was ist statistisch gesehen die häufigste Ursache für virusbedingte Schädigungen des Ungeborenen, über die aber kaum gesprochen wird?',
        'options': [
            'Röteln (durch ungeimpfte Erwachsene).',
            'Listerien (durch Rohmilchkäse).',
            'Das Cytomegalievirus (CMV). Die Hauptansteckungsquelle ist der Speichel oder Urin von Kleinkindern.',
            'Salmonellen (durch rohe Eier).'
        ],
        'correctIndices': [2],
        'explanation': 'CMV ist für das Ungeborene gefährlich (Hörschäden, Entwicklungsverzögerung). Hygiene beim Wickeln und kein "Schnuller-Ablecken" sind der beste Schutz.',
        'tips': 'Fast jeder kennt "Katzenklo meiden" (Toxoplasmose), aber kaum ein Arzt warnt vor dem Speichel des eigenen Kleinkindes. Hygiene beim Wickeln und kein Schnuller-Ablecken schützen.',
        'sourceLabel': 'Robert Koch-Institut (RKI) Ratgeber Cytomegalievirus',
        'sourceUrl': None,
        'difficulty': 3,
        'isActive': True
    },
    {
        'categoryId': 'schwangerschaft',
        'text': 'Warum wird Schwangeren geraten, im zweiten Trimester eine professionelle Zahnreinigung durchführen zu lassen?',
        'options': [
            'Weil die Zähne durch den Kalkbedarf des Babys weicher werden.',
            'Schwangerschaftshormone machen das Zahnfleisch durchlässiger. Eine unbehandelte Parodontitis erhöht das Risiko für eine Frühgeburt signifikant.',
            'Damit das Baby später weißere Zähne bekommt.',
            'Um Mundgeruch durch Sodbrennen zu vermeiden.'
        ],
        'correctIndices': [1],
        'explanation': 'Der Mund ist das Tor zum Körper. Entzündungsbotenstoffe aus dem Zahnfleisch können vorzeitige Wehen auslösen.',
        'tips': 'Schwangerschaftshormone machen das Zahnfleisch durchlässiger. Eine professionelle Zahnreinigung im zweiten Trimester ist eine wichtige Vorsorgemaßnahme.',
        'sourceLabel': 'Bundeszahnärztekammer / DGZMK',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'schwangerschaft',
        'text': 'Ein alter Spruch besagt: "Du musst jetzt für zwei essen!" Wie viel zusätzliche Kalorien braucht eine Schwangere im letzten Drittel der Schwangerschaft wirklich pro Tag?',
        'options': [
            'Doppelt so viele wie vorher (ca. 4000 kcal).',
            'Gar keine zusätzlichen Kalorien.',
            'Nur etwa 250 bis 500 kcal (das entspricht etwa einem belegten Brot oder einer kleinen Portion Müsli).',
            'Mindestens 1000 kcal extra.'
        ],
        'correctIndices': [2],
        'explanation': 'Der Nährstoffbedarf (Vitamine/Mineralien) steigt stark, aber der Kalorienbedarf kaum. "Klasse statt Masse" ist die Devise.',
        'tips': 'Der alte Spruch "für zwei essen" ist ein Mythos. Du brauchst nur etwa 250-500 kcal extra – das entspricht einem belegten Brot. Fokus auf Nährstoffqualität, nicht Menge.',
        'sourceLabel': 'Deutsche Gesellschaft für Ernährung (DGE)',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'schwangerschaft',
        'text': 'Früher hieß es "Schonen!". Was ist die heutige Empfehlung für gesunde Schwangere in Bezug auf Sport (z.B. Joggen, Schwimmen, Yoga)?',
        'options': [
            'Sport ist im ersten Drittel verboten, um Fehlgeburten zu vermeiden.',
            'Moderate Bewegung ist ausdrücklich erwünscht. Sie beugt Schwangerschaftsdiabetes vor, verbessert die Stimmung und kann die Geburt erleichtern.',
            'Nur Bettruhe ist sicher.',
            'Nur Dehnübungen sind erlaubt, kein Ausdauersport.'
        ],
        'correctIndices': [1],
        'explanation': 'Solange keine medizinischen Risiken vorliegen, ist Sport gesund. Tabu sind nur Kontaktsportarten (Verletzungsgefahr) oder Tauchen.',
        'tips': 'Früher hieß es "Schonen!", heute ist moderate Bewegung erwünscht. Sie beugt Schwangerschaftsdiabetes vor und kann die Geburt erleichtern. Höre auf deinen Körper.',
        'sourceLabel': 'Deutsche Sporthochschule Köln / Leitlinien der DGGG',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'schwangerschaft',
        'text': 'Darf man sich in der Schwangerschaft die Haare färben?',
        'options': [
            'Nein, die Chemikalien gehen sofort ins Gehirn des Babys.',
            'Ja, aber man sollte idealerweise das erste Trimester abwarten und Produkte ohne Ammoniak verwenden. Es gibt keinen Beleg für Schäden, aber Vorsicht ist die Mutter der Porzellankiste.',
            'Nur mit Pflanzenfarbe (Henna), alles andere ist verboten.',
            'Ja, ohne jegliche Einschränkungen.'
        ],
        'correctIndices': [1],
        'explanation': 'Es gibt keinen wissenschaftlichen Beleg für Schäden durch Haarfärbemittel, aber aus Vorsichtsgründen wird empfohlen, das erste Trimester abzuwarten.',
        'tips': 'Wenn du dir unsicher bist, warte das erste Trimester ab und verwende Produkte ohne Ammoniak. Strähnchen sind eine gute Alternative, da sie nicht die Kopfhaut berühren.',
        'sourceLabel': 'NHS (National Health Service UK) / Embryotox',
        'sourceUrl': None,
        'difficulty': 1,
        'isActive': True
    },
    {
        'categoryId': 'schwangerschaft',
        'text': 'Warum sind Salami und Camembert oft tabu in der Schwangerschaft?',
        'options': [
            'Wegen des hohen Fettgehalts.',
            'Wegen der Gefahr von Listerien und Toxoplasmose. Diese Erreger sterben erst beim Erhitzen oder langen Reifeprozessen ab.',
            'Weil sie Allergien auslösen.',
            'Weil sie zu viel Salz enthalten.'
        ],
        'correctIndices': [1],
        'explanation': 'Kochschinken ist okay (gekocht), Salami ist roh (geräuchert/luftgetrocknet) → Risiko. Salami auf der Pizza (im Ofen bei 200 Grad) ist wieder okay!',
        'tips': 'Wichtiger Alltags-Hack: Salami auf der Pizza ist sicher, weil sie im Ofen erhitzt wurde! Kochschinken ist okay, roher Schinken nicht. Erhitzen tötet die Erreger ab.',
        'sourceLabel': 'Lebensmittelsicherheit in der Schwangerschaft',
        'sourceUrl': None,
        'difficulty': 1,
        'isActive': True
    },
    {
        'categoryId': 'schwangerschaft',
        'text': 'Welche Schlafposition wird Schwangeren ab dem zweiten Trimester empfohlen?',
        'options': [
            'Auf dem Rücken, um die Wirbelsäule zu entlasten.',
            'Auf dem Bauch mit einem speziellen Kissen.',
            'Auf der linken Seite, um die Durchblutung der Plazenta zu optimieren.',
            'Die Schlafposition spielt keine Rolle.'
        ],
        'correctIndices': [2],
        'explanation': 'Die linke Seitenlage verhindert, dass die wachsende Gebärmutter auf die große Hohlvene (Vena Cava) drückt, was die Blutzufuhr zum Baby verbessern kann.',
        'tips': 'Ein Stillkissen zwischen den Knien macht die Seitenlage bequemer. Wenn du nachts auf dem Rücken aufwachst, ist das kein Drama – dreh dich einfach wieder auf die Seite.',
        'sourceLabel': 'Geburtshilfe-Leitlinien',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'schwangerschaft',
        'text': 'Ab wann kann ein Schwangerschaftstest zuverlässig eine Schwangerschaft nachweisen?',
        'options': [
            'Sofort nach dem Geschlechtsverkehr.',
            'Etwa 1-2 Tage nach der ausgebliebenen Periode.',
            'Etwa 10-14 Tage nach der Empfängnis (ca. zum Zeitpunkt der ausbleibenden Periode).',
            'Erst nach 4 Wochen.'
        ],
        'correctIndices': [2],
        'explanation': 'Das Schwangerschaftshormon hCG ist etwa 10-14 Tage nach der Empfängnis im Urin nachweisbar, was ungefähr dem Zeitpunkt der ausbleibenden Periode entspricht.',
        'tips': 'Frühtests können schon einige Tage vor der Periode anschlagen, sind aber weniger zuverlässig. Der beste Zeitpunkt ist der erste Tag der ausbleibenden Periode mit Morgenurin.',
        'sourceLabel': 'Gynäkologische Fachliteratur',
        'sourceUrl': None,
        'difficulty': 1,
        'isActive': True
    },
    {
        'categoryId': 'schwangerschaft',
        'text': 'Warum sollten Schwangere auf rohen Fisch (z.B. Sushi) verzichten?',
        'options': [
            'Wegen des hohen Jodgehalts.',
            'Wegen möglicher Parasiten und Bakterien, die dem Baby schaden können.',
            'Weil Fisch generell in der Schwangerschaft verboten ist.',
            'Wegen des Quecksilbergehalts, der nur in rohem Fisch gefährlich ist.'
        ],
        'correctIndices': [1],
        'explanation': 'Roher Fisch kann Parasiten (z.B. Nematoden) und Bakterien (z.B. Listerien) enthalten. Gekochter oder gebratener Fisch ist hingegen sicher und sogar empfohlen wegen der Omega-3-Fettsäuren.',
        'tips': 'Du musst nicht auf Sushi verzichten – wähle einfach gekochte Varianten wie Ebi (gekochte Garnelen) oder vegetarisches Sushi. Fisch ist gesund, er muss nur durchgegart sein.',
        'sourceLabel': 'Ernährungsempfehlungen für Schwangere',
        'sourceUrl': None,
        'difficulty': 1,
        'isActive': True
    }
]


def upload_categories(db):
    """Upload category data to Firestore."""
    print("Uploading categories...")
    category_ref = db.collection('categories')

    # Count questions per category
    category_counts = {}
    for question in QUESTIONS:
        cat_id = question['categoryId']
        category_counts[cat_id] = category_counts.get(cat_id, 0) + 1

    for category in CATEGORIES:
        # Add totalQuestions field
        category_data = category.copy()
        category_data['totalQuestions'] = category_counts.get(category['id'], 0)

        doc_ref = category_ref.document(category['id'])
        doc_ref.set(category_data)
        print(f"  ✓ Uploaded category: {category['title']} ({category_data['totalQuestions']} questions)")

    print(f"Successfully uploaded {len(CATEGORIES)} categories.\n")


def upload_questions(db):
    """Upload question data to Firestore."""
    print("Uploading questions...")
    question_ref = db.collection('questions')

    for i, question in enumerate(QUESTIONS, 1):
        # Auto-generate question ID
        doc_ref = question_ref.document()
        doc_ref.set(question)
        print(f"  ✓ Uploaded question {i}/{len(QUESTIONS)}: {question['text'][:60]}...")

    print(f"\nSuccessfully uploaded {len(QUESTIONS)} questions.")

    # Print summary by category
    print("\nSummary by category:")
    category_counts = {}
    for question in QUESTIONS:
        cat_id = question['categoryId']
        category_counts[cat_id] = category_counts.get(cat_id, 0) + 1

    for cat_id, count in category_counts.items():
        cat_name = next((c['title'] for c in CATEGORIES if c['id'] == cat_id), cat_id)
        print(f"  - {cat_name}: {count} questions")


def main():
    """Main function to upload all data."""
    print("=" * 60)
    print("Firebase Question Upload Script")
    print("=" * 60)
    print()

    try:
        # Initialize Firebase
        print("Initializing Firebase connection...")
        db = initialize_firebase()
        print("✓ Connected to Firebase\n")

        # Upload data
        upload_categories(db)
        upload_questions(db)

        print("\n" + "=" * 60)
        print("Upload completed successfully!")
        print("=" * 60)

    except FileNotFoundError:
        print("\n❌ ERROR: serviceAccountKey.json not found!")
        print("\nPlease follow these steps:")
        print("1. Go to Firebase Console (https://console.firebase.google.com)")
        print("2. Select your project")
        print("3. Go to Project Settings > Service Accounts")
        print("4. Click 'Generate New Private Key'")
        print("5. Save the downloaded file as 'serviceAccountKey.json' in this directory")
        sys.exit(1)

    except Exception as e:
        print(f"\n❌ ERROR: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
