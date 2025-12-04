#!/usr/bin/env python3
"""
Firebase Question Upload Script for Erziehungsapp
Uploads categories and questions from Erziehungsapp.md to Firestore.
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
        cred = credentials.Certificate('serviceAccountKey.json')
        app = firebase_admin.initialize_app(cred)

    return firestore.client()

# Category definitions
CATEGORIES = [
    {
        'id': 'buerokratisches',
        'title': 'Bürokratisches / Hilfeinstanzen',
        'description': 'Fragen zu Behördengängen, Dokumenten und rechtlichen Themen rund um Elternschaft',
        'order': 1,
        'iconName': 'description',
        'isPremium': False
    },
    {
        'id': 'motorik',
        'title': 'Motorik / Wachstum / Bewegung',
        'description': 'Fragen zur motorischen Entwicklung, Wachstum und Bewegung von Kindern',
        'order': 2,
        'iconName': 'directions_run',
        'isPremium': False
    }
]

# Questions data
QUESTIONS = [
    # Bürokratisches / Hilfeinstanzen
    {
        'categoryId': 'buerokratisches',
        'text': 'Ihr wollt mit eurem 3 Monate alten Baby "nur mal schnell" über die Grenze nach Österreich oder in die Niederlande fahren. Was gilt bezüglich Ausweisdokumenten?',
        'options': [
            'Innerhalb der EU/Schengen-Raum reicht die Geburtsurkunde des Kindes völlig aus.',
            'Solange das Baby noch gestillt wird, reicht der Eintrag im Reisepass der Mutter.',
            'Jedes Kind braucht ab Geburt ein eigenes, gültiges Ausweisdokument (Personalausweis oder Reisepass) für jeden Grenzübertritt.',
            'Unter 6 Monaten besteht noch keine Ausweispflicht, da sich das Gesicht zu schnell verändert.'
        ],
        'correctIndices': [2],
        'explanation': 'Viele denken: "Schengen = keine Grenzen = keine Papiere". Das ist falsch. Bei einer Kontrolle ohne Dokument kann es zu Problemen kommen. Der klassische "Kinderreisepass" wurde zum 1.1.2024 abgeschafft. Jetzt gibt es nur noch den normalen Reisepass (teurer, hält länger) oder Personalausweis.',
        'tips': 'Ihr wollt in den Urlaub? Beantragt möglichst frühzeitig einen Ausweis, da die Terminvergabe und die Bearbeitungszeit des Amtes häufig lange dauert.',
        'sourceLabel': 'Auswärtiges Amt / Bundesministerium des Innern',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'buerokratisches',
        'text': 'Ein unverheiratetes Paar bekommt ein Kind. Der Vater erkennt die Vaterschaft vor der Geburt offiziell beim Jugendamt an und steht in der Geburtsurkunde. Wer hat das Sorgerecht?',
        'options': [
            'Automatisch beide Elternteile, da die Vaterschaft anerkannt ist.',
            'Automatisch erst einmal nur die Mutter. Das gemeinsame Sorgerecht muss separat per "Sorgeerklärung" beurkundet werden.',
            'Beide, aber nur wenn sie zusammen wohnen (Meldeadresse).',
            'Das entscheidet das Familiengericht nach der Geburt.'
        ],
        'correctIndices': [1],
        'explanation': '"Vaterschaftsanerkennung" und "Sorgerecht" sind zwei völlig verschiedene Paar Schuhe. Ohne die zweite Unterschrift (Sorgeerklärung) darf der Vater im Ernstfall (z.B. medizinische Entscheidungen) rechtlich nicht mitentscheiden.',
        'tips': 'Macht einen Abwasch draus! Ihr könnt die Sorgeerklärung oft direkt zeitgleich mit der Vaterschaftsanerkennung beim Jugendamt unterschreiben. Das spart euch einen zweiten Behördengang nach der Geburt. Kümmert euch am besten schon in der Schwangerschaft darum.',
        'sourceLabel': 'BGB § 1626a / Bundesministerium für Familie, Senioren, Frauen und Jugend (BMFSFJ)',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'buerokratisches',
        'text': 'Ihr plant eure Elternzeit. Wie viele Monate Basiselterngeld kann ein Elternteil maximal alleine beziehen (ohne dass der andere Partner Elterngeld nimmt)?',
        'options': [
            '14 Monate',
            '12 Monate',
            '10 Monate',
            'So lange man möchte, bis das Kind 3 Jahre alt ist.'
        ],
        'correctIndices': [1],
        'explanation': 'Man hört immer "Es gibt 14 Monate Elterngeld". Das stimmt aber nur, wenn sich beide beteiligen. Einer alleine bekommt maximal 12. Die zusätzlichen 2 Monate ("Partnermonate") gibt es nur, wenn der andere Partner auch mindestens 2 Monate Einkommenseinbußen hat und das Kind betreut.',
        'tips': 'Das Elterngeld berechnet sich nach dem Netto-Einkommen der letzten 12 Monate vor der Geburt/Mutterschutz. Wenn verheiratete Paare rechtzeitig (mindestens 7 Monate vor Mutterschutz-Beginn) die Steuerklasse wechseln, kann das Elterngeld um mehrere hundert Euro monatlich steigen. Füllt den Antrag schon vor der Geburt so weit wie möglich aus!',
        'sourceLabel': 'Bundeselterngeld- und Elternzeitgesetz (BEEG)',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'buerokratisches',
        'text': 'Das Baby ist da! Herzlichen Glückwunsch. Bei welcher Behörde muss das Kind innerhalb der ersten Lebenswoche (meist binnen 7 Werktagen) offiziell angemeldet werden, um eine Geburtsurkunde zu erhalten?',
        'options': [
            'Einwohnermeldeamt (des Geburtsortes)',
            'Jugendamt (des Geburtsortes)',
            'Standesamt (des Geburtsortes)',
            'Finanzamt (des Geburtsortes)'
        ],
        'correctIndices': [2],
        'explanation': 'Oft übernimmt das Krankenhaus die Weiterleitung der Anzeige, aber zuständig für die Urkunde ist das Standesamt. Ohne Geburtsurkunde kein Kindergeld und kein Elterngeld!',
        'tips': 'Viele Krankenhäuser bieten einen Anmeldeservice direkt auf der Station an! Packt dafür unbedingt das Stammbuch bzw. eure Heiratsurkunde (oder bei Unverheirateten: eigene Geburtsurkunden & Vaterschaftsanerkennung) schon vor der Geburt in die Kliniktasche. Kreuzt im Formular direkt an, dass ihr „zweckgebundene Originale" benötigt (für Elterngeld, Kindergeld und Krankenkasse).',
        'sourceLabel': 'Personenstandsgesetz (PstG)',
        'sourceUrl': None,
        'difficulty': 1,
        'isActive': True
    },
    {
        'categoryId': 'buerokratisches',
        'text': 'Im Stress der ersten Monate habt ihr vergessen, den Kindergeldantrag abzuschicken. Wie lange wird Kindergeld maximal rückwirkend ausgezahlt?',
        'options': [
            'Gar nicht, das Geld für die vergangenen Monate ist weg.',
            'Bis zu 4 Jahre rückwirkend.',
            'Nur für die letzten 6 Monate vor Eingang des Antrags.',
            'Bis zum 1. Geburtstag des Kindes.'
        ],
        'correctIndices': [2],
        'explanation': 'Diese Frist wurde vor einigen Jahren verkürzt (früher waren es 4 Jahre). Wer den Antrag erst zum 1. Geburtstag stellt, verliert also das Geld der ersten 6 Monate!',
        'tips': 'Auch hier lohnt es sich den Antrag bereits vor der Geburt „vorzubereiten" und nach der Geburt nur noch die fehlenden Daten hinzuzufügen.',
        'sourceLabel': 'Bundesagentur für Arbeit / Einkommensteuergesetz (EStG)',
        'sourceUrl': None,
        'difficulty': 2,
        'isActive': True
    },
    {
        'categoryId': 'buerokratisches',
        'text': 'Wie lange dauert die gesetzliche Mutterschutzfrist nach der Geburt (bei einer unkomplizierten Geburt, keine Früh- oder Mehrlingsgeburt), in der die Mutter im Normalfall nicht arbeiten darf?',
        'options': [
            '4 Wochen',
            '6 Wochen',
            '8 Wochen',
            '12 Wochen'
        ],
        'correctIndices': [2],
        'explanation': 'In diesen 8 Wochen nach der Geburt besteht ein absolutes Beschäftigungsverbot für den Arbeitgeber (außer in sehr seltenen Ausnahmen auf ausdrücklichen Wunsch der Mutter, was aber fast nie vorkommt). Bei Frühchen/Zwillingen sind es 12 Wochen.',
        'tips': 'Damit du pünktlich dein Mutterschaftsgeld bekommst, brauchst du das "Zeugnis über den mutmaßlichen Tag der Entbindung". Dein Frauenarzt darf dir diesen gelben Schein frühestens 7 Wochen vor dem Termin ausstellen. Mach dir dafür am besten schon jetzt eine Erinnerung ins Handy.',
        'sourceLabel': 'Mutterschutzgesetz (MuSchG)',
        'sourceUrl': None,
        'difficulty': 1,
        'isActive': True
    },

    # Motorik / Wachstum / Bewegung
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
    {
        'categoryId': 'motorik',
        'text': 'Ein 10 Monate altes Baby greift Spielzeug, Löffel und Bausteine ausschließlich mit der linken Hand. Die rechte Hand wird kaum aktiv genutzt, bleibt oft gefäustet. Die Eltern freuen sich über den „entschlossenen kleinen Linkshänder". Wie bewerten Entwicklungsneurologen diese Situation?',
        'options': [
            'Es ist ein positives Zeichen für eine frühe kognitive Reifung, da sich die Gehirndominanz schneller als beim Durchschnitt etabliert hat.',
            'Es ist eine normale genetische Variation; die Händigkeit ist bereits im Mutterleib festgelegt und zeigt sich bei manchen Kindern eben früher.',
            'Es ist ein medizinisches Warnsignal. Eine klare Handdominanz vor dem 12.–18. Lebensmonat ist pathologisch und deutet oft auf eine motorische Störung (z.B. leichte Hemiparese) der anderen (inaktiven) Körperseite hin.',
            'Es ist ein Hinweis darauf, dass das Kind im „Sprung" ist und die rechte Gehirnhälfte gerade umgebaut wird, weshalb die linke Hand (gesteuert von rechts) aktiver ist.'
        ],
        'correctIndices': [2],
        'explanation': 'Ein gesundes Baby sollte beide Hände benutzen. Wenn es sich unter 1 Jahr schon festlegt, liegt das meist daran, dass die andere Seite eingeschränkt ist. Ein echter Linkshänder zeigt sich meist erst ab 2–3 Jahren.',
        'tips': 'Wenn dein Baby unter 12 Monaten nur eine Hand benutzt, sprich mit deinem Kinderarzt. Eine frühe Handdominanz kann auf eine motorische Störung hinweisen.',
        'sourceLabel': 'Vojta-Diagnostik / Largo, R. (Babyjahre)',
        'sourceUrl': None,
        'difficulty': 3,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Ein 3-jähriges Kind steht im Badezimmer vor dir. Dabei fallen deutlich sichtbare „X-Beine" (Genu valgum) auf: Die Knie berühren sich, während die Knöchel weit auseinander stehen. Das Kind läuft jedoch schmerzfrei. Was ist die korrekte physiologische Einschätzung?',
        'options': [
            'Dies ist in diesem Alter physiologisch völlig normal. Die Beinachse entwickelt sich von O-Beinen (Säugling) über X-Beine (Kleinkind/Vorschulalter) hin zu geraden Beinen (Schulalter).',
            'Das ist ein klassisches Anzeichen für einen Vitamin-D-Mangel (Rachitis), der sofort hochdosiert supplementiert werden muss.',
            'Dies deutet auf eine Bindegewebsschwäche hin, die durch zu frühes Tragen von festem Schuhwerk verursacht wurde.',
            'Das Kind hat vermutlich eine Hüftdysplasie, die im Säuglingsalter übersehen wurde.'
        ],
        'correctIndices': [0],
        'explanation': 'Die X-Bein-Stellung bei 3-Jährigen ist physiologisch normal. Die Beinachse entwickelt sich von O-Beinen über X-Beine zu geraden Beinen im Schulalter.',
        'tips': 'Wenn dein Kind X-Beine hat, aber schmerzfrei läuft, ist das meist normal. Bei Schmerzen oder extremer Ausprägung solltest du einen Kinderorthopäden aufsuchen.',
        'sourceLabel': 'Leitlinien Kinderorthopädie',
        'sourceUrl': None,
        'difficulty': 3,
        'isActive': True
    },
    {
        'categoryId': 'motorik',
        'text': 'Viele Eltern hören bei der U-Untersuchung oder vom Physiotherapeuten den Begriff „Rumpfhypotonie" (zu schlaffer Rumpf). Was ist der medizinisch genaue Unterschied zwischen „Muskeltonus" und „Muskelkraft", die von Laien oft verwechselt werden?',
        'options': [
            'Es gibt keinen Unterschied, es sind zwei Begriffe für dasselbe Phänomen.',
            'Hypotonie bedeutet, dass die Muskeln verkürzt sind, während Kraft die Länge beschreibt.',
            'Der Tonus ist die neurologische Grundspannung im Ruhezustand (wie gespannt das "Gummiband" ist). Kraft ist die Fähigkeit, aktiv ein Gewicht zu bewegen. Ein Kind kann hypoton sein (weich wie Wackelpudding), aber trotzdem viel Kraft haben, wenn es sich anstrengt.',
            'Tonus beschreibt die Ausdauer, Kraft beschreibt die Maximalkraft.'
        ],
        'correctIndices': [2],
        'explanation': 'Hypotonie ist eine Sache des Nervensystems/Gehirns, Kraft ist Muskelsache. Ein hypotones Kind muss lernen, seine Kraft schneller abzurufen, um die fehlende Grundspannung auszugleichen.',
        'tips': 'Wenn dein Kind hypoton ist, bedeutet das nicht automatisch, dass es schwach ist. Es braucht nur mehr Zeit, um die Kraft zu aktivieren.',
        'sourceLabel': 'Pädiatrische Physiotherapie',
        'sourceUrl': None,
        'difficulty': 3,
        'isActive': True
    }
]


def upload_categories(db):
    """Upload category data to Firestore."""
    print("Uploading categories...")
    category_ref = db.collection('categories')

    for category in CATEGORIES:
        doc_ref = category_ref.document(category['id'])
        doc_ref.set(category)
        print(f"  ✓ Uploaded category: {category['title']}")

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
    print("Firebase Question Upload Script - Erziehungsapp")
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
