import Foundation

struct BibleVerse: Identifiable, Hashable, Sendable {
    let reference: String
    let text: String
    let theme: VerseTheme

    var id: String { reference }
}

enum BibleVerses {

    static let all: [BibleVerse] = [
        // MARK: Strength (5)
        BibleVerse(reference: "Psalm 144:1", text: "Praise be to the LORD my Rock, who trains my hands for war, my fingers for battle.", theme: .strength),
        BibleVerse(reference: "Philippians 4:13", text: "I can do all this through him who gives me strength.", theme: .strength),
        BibleVerse(reference: "Isaiah 40:29–31", text: "He gives strength to the weary and increases the power of the weak. Even youths grow tired and weary, and young men stumble and fall; but those who hope in the LORD will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint.", theme: .strength),
        BibleVerse(reference: "Ephesians 6:10", text: "Finally, be strong in the Lord and in his mighty power.", theme: .strength),
        BibleVerse(reference: "Psalm 18:32–34", text: "It is God who arms me with strength and keeps my way secure. He makes my feet like the feet of a deer; he causes me to stand on the heights. He trains my hands for battle; my arms can bend a bow of bronze.", theme: .strength),

        // MARK: Perseverance (6)
        BibleVerse(reference: "Hebrews 12:1–2", text: "Therefore, since we are surrounded by such a great cloud of witnesses, let us throw off everything that hinders and the sin that so easily entangles. And let us run with perseverance the race marked out for us, fixing our eyes on Jesus, the pioneer and perfecter of faith.", theme: .perseverance),
        BibleVerse(reference: "James 1:2–4", text: "Consider it pure joy, my brothers and sisters, whenever you face trials of many kinds, because you know that the testing of your faith produces perseverance. Let perseverance finish its work so that you may be mature and complete, not lacking anything.", theme: .perseverance),
        BibleVerse(reference: "Romans 5:3–4", text: "Not only so, but we also glory in our sufferings, because we know that suffering produces perseverance; perseverance, character; and character, hope.", theme: .perseverance),
        BibleVerse(reference: "Galatians 6:9", text: "Let us not become weary in doing good, for at the proper time we will reap a harvest if we do not give up.", theme: .perseverance),
        BibleVerse(reference: "2 Timothy 4:7", text: "I have fought the good fight, I have finished the race, I have kept the faith.", theme: .perseverance),
        BibleVerse(reference: "1 Corinthians 9:24–27", text: "Do you not know that in a race all the runners run, but only one gets the prize? Run in such a way as to get the prize. Everyone who competes in the games goes into strict training. They do it to get a crown that will not last, but we do it to get a crown that will last forever. Therefore I do not run like someone running aimlessly; I do not fight like a boxer beating the air. No, I strike a blow to my body and make it my slave so that after I have preached to others, I myself will not be disqualified for the prize.", theme: .perseverance),

        // MARK: Discipline (5)
        BibleVerse(reference: "2 Timothy 1:7", text: "For the Spirit God gave us does not make us timid, but gives us power, love and self-discipline.", theme: .discipline),
        BibleVerse(reference: "Proverbs 25:28", text: "Like a city whose walls are broken through is a person who lacks self-control.", theme: .discipline),
        BibleVerse(reference: "1 Corinthians 6:19–20", text: "Do you not know that your bodies are temples of the Holy Spirit, who is in you, whom you have received from God? You are not your own; you were bought at a price. Therefore honor God with your bodies.", theme: .discipline),
        BibleVerse(reference: "1 Timothy 4:7–8", text: "Have nothing to do with godless myths and old wives' tales; rather, train yourself to be godly. For physical training is of some value, but godliness has value for all things, holding promise for both the present life and the life to come.", theme: .discipline),
        BibleVerse(reference: "1 Corinthians 10:31", text: "So whether you eat or drink or whatever you do, do it all for the glory of God.", theme: .discipline),

        // MARK: Warfare / Courage (5)
        BibleVerse(reference: "Joshua 1:9", text: "Have I not commanded you? Be strong and courageous. Do not be afraid; do not be discouraged, for the LORD your God will be with you wherever you go.", theme: .warfare),
        BibleVerse(reference: "Deuteronomy 31:6", text: "Be strong and courageous. Do not be afraid or terrified because of them, for the LORD your God goes with you; he will never leave you nor forsake you.", theme: .warfare),
        BibleVerse(reference: "Ephesians 6:11–13", text: "Put on the full armor of God, so that you can take your stand against the devil's schemes. For our struggle is not against flesh and blood, but against the rulers, against the authorities, against the powers of this dark world and against the spiritual forces of evil in the heavenly realms. Therefore put on the full armor of God, so that when the day of evil comes, you may be able to stand your ground, and after you have done everything, to stand.", theme: .warfare),
        BibleVerse(reference: "2 Corinthians 10:3–5", text: "For though we live in the world, we do not wage war as the world does. The weapons we fight with are not the weapons of the world. On the contrary, they have divine power to demolish strongholds. We demolish arguments and every pretension that sets itself up against the knowledge of God, and we take captive every thought to make it obedient to Christ.", theme: .warfare),
        BibleVerse(reference: "1 Samuel 17:45", text: "David said to the Philistine, 'You come against me with sword and spear and javelin, but I come against you in the name of the LORD Almighty, the God of the armies of Israel, whom you have defied.'", theme: .warfare),

        // MARK: Rest / Sabbath (5)
        BibleVerse(reference: "Matthew 11:28–30", text: "Come to me, all you who are weary and burdened, and I will give you rest. Take my yoke upon you and learn from me, for I am gentle and humble in heart, and you will find rest for your souls. For my yoke is easy and my burden is light.", theme: .rest),
        BibleVerse(reference: "Psalm 23:1–3", text: "The LORD is my shepherd, I lack nothing. He makes me lie down in green pastures, he leads me beside quiet waters, he refreshes my soul.", theme: .rest),
        BibleVerse(reference: "Mark 2:27", text: "Then he said to them, 'The Sabbath was made for man, not man for the Sabbath.'", theme: .rest),
        BibleVerse(reference: "Psalm 127:2", text: "In vain you rise early and stay up late, toiling for food to eat— for he grants sleep to those he loves.", theme: .rest),
        BibleVerse(reference: "Exodus 20:8–10", text: "Remember the Sabbath day by keeping it holy. Six days you shall labor and do all your work, but the seventh day is a sabbath to the LORD your God.", theme: .rest),

        // MARK: Identity (5)
        BibleVerse(reference: "Galatians 2:20", text: "I have been crucified with Christ and I no longer live, but Christ lives in me. The life I now live in the body, I live by faith in the Son of God, who loved me and gave himself for me.", theme: .identity),
        BibleVerse(reference: "Ephesians 2:10", text: "For we are God's handiwork, created in Christ Jesus to do good works, which God prepared in advance for us to do.", theme: .identity),
        BibleVerse(reference: "1 John 3:1", text: "See what great love the Father has lavished on us, that we should be called children of God! And that is what we are!", theme: .identity),
        BibleVerse(reference: "2 Corinthians 5:17", text: "Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here!", theme: .identity),
        BibleVerse(reference: "Romans 8:37", text: "No, in all these things we are more than conquerors through him who loved us.", theme: .identity),

        // MARK: Failure & Return (5)
        BibleVerse(reference: "Proverbs 24:16", text: "For though the righteous fall seven times, they rise again, but the wicked stumble when calamity strikes.", theme: .failureAndReturn),
        BibleVerse(reference: "Lamentations 3:22–23", text: "Because of the LORD's great love we are not consumed, for his compassions never fail. They are new every morning; great is your faithfulness.", theme: .failureAndReturn),
        BibleVerse(reference: "1 John 1:9", text: "If we confess our sins, he is faithful and just and will forgive us our sins and purify us from all unrighteousness.", theme: .failureAndReturn),
        BibleVerse(reference: "Micah 7:8", text: "Do not gloat over me, my enemy! Though I have fallen, I will rise. Though I sit in darkness, the LORD will be my light.", theme: .failureAndReturn),
        BibleVerse(reference: "Psalm 51:10–12", text: "Create in me a pure heart, O God, and renew a steadfast spirit within me. Do not cast me from your presence or take your Holy Spirit from me. Restore to me the joy of your salvation and grant me a willing spirit, to sustain me.", theme: .failureAndReturn),

        // MARK: Trust (3)
        BibleVerse(reference: "Proverbs 3:5–6", text: "Trust in the LORD with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.", theme: .trust),
        BibleVerse(reference: "Psalm 46:10", text: "He says, 'Be still, and know that I am God; I will be exalted among the nations, I will be exalted in the earth.'", theme: .trust),
        BibleVerse(reference: "Jeremiah 29:11", text: "For I know the plans I have for you, declares the LORD, plans to prosper you and not to harm you, plans to give you hope and a future.", theme: .trust),

        // MARK: Work & Purpose (2)
        BibleVerse(reference: "Colossians 3:23–24", text: "Whatever you do, work at it with all your heart, as working for the Lord, not for human masters, since you know that you will receive an inheritance from the Lord as a reward. It is the Lord Christ you are serving.", theme: .workAndPurpose),
        BibleVerse(reference: "Ecclesiastes 9:10", text: "Whatever your hand finds to do, do it with all your might, for in the realm of the dead, where you are going, there is neither working nor planning nor knowledge nor wisdom.", theme: .workAndPurpose)
    ]

    static func byReference(_ ref: String) -> BibleVerse? {
        all.first { $0.reference == ref }
    }

    static func byTheme(_ theme: VerseTheme) -> [BibleVerse] {
        all.filter { $0.theme == theme }
    }
}
