------------------------------------------------------------------------------------------------------
-- Necrosis LdC
--
-- Original creator (US): Infernal (http://www.shadydesign.com/necrosis/files/)
-- Base implementation (FR): Tilienna Thorondor
-- Project continuation: Lomig & Nyx of Larmes de Cenarius, Kael'Thas
-- French skins and voices: Eliah, Ner'zhul
-- Version 01.05.2006-2
------------------------------------------------------------------------------------------------------


-- Warlock summoning texts
----------------------------------------
-- Below are the summoning texts for the warlock. You can customise them
-- So they better match your character!
-- Here is a quick guide:
-- Summoning lines follow the pattern "Blah blah blah" summoned player "Blah blah blah"
-- If you want to write "I summon you 'Player name' if you click my portal"
-- Remember that the target's name is replaced by <target>
-- then add before }:
-- "I summon you, <target>, if you click my portal"
--
-- The same logic applies to Soulstone messages
--
-- Demon summoning looks complicated but it really is not
-- Each demon is numbered from 1 to 4
-- Inside each demon section every summoning speech is numbered from 1 to x
-- Within these summoning speeches you can insert new lines in the chat window
-- I hope the comments I added are understandable
-- Otherwise feel free to post on the forum thread or email me (lomig@larmes-cenarius.net)


-- Texts for a summoning by a warlock
--------------------------------------
-- Here are some summoning speeches for your warlock. Feel free to change them to
-- so they fit your warlock's personality a bit more!
-- Need some help? :)
-- Correct syntax is "Blah blah blah" SelectedPlayer "Blah blah blah"
-- If you want to write "In a few seconds 'Player name' will be able to help us"
-- The target's name is replaced with <target>
-- you need to add before the } :
-- "In a few seconds <target> will be able to help us",
-- 
-- The same mechanism exists for soulstone messages
--
-- As for the demon summoning, it seems to be complicated but it is not
-- Each demon is numbered from 1 to 4
-- Inside those demon sections, each summoning speech is numbered from 1 to x
-- These speeches can span multiple sentences in the in-game chat window
-- I added notes to the example sentences; I hope they are clear
-- If not, do not hesitate to email me (lomig@larmes-cenarius.net)


-- Texts for the Ritual of Summoning
----------------------------------------
-- Here are some summoning texts for your warlock. You can adjust them
-- to tailor them to your warlock mindset!
-- Here are a few tips. :)
-- The correct syntax is "Blah blah blah" selected player "Blah blah blah"
-- If you want to write "In wenigen Sekunden wird 'Spielername' in der Lage sein uns zu helfen"
-- add before the };
-- "In wenigen Sekunden wird <target> in der Lage sein uns zu helfen",
-- 
-- The same applies to soulstone messages.
--
-- Summoning demons may look complicated, but it really is not
-- Each demon is numbered from 1 to 4
-- Within each demon list every summoning speech is numbered from 1 to X
-- These speeches can include several lines which will appear in game in the chat window
-- I added a few comments to the example sentences and hope they are understandable
-- If anything is unclear, feel free to contact me (lomig@larmes-cenarius.net)


-------------------------------------
--  ENGLISH VERSION --
-------------------------------------

function Necrosis_Localization_Speech_En()

	NECROSIS_INVOCATION_MESSAGES = {
		[1] = {
			"Arcanum Taxi Cab! I am summoning <target>, please click on the portal.",
		},
		[2] = {
			"Welcome aboard, <target>, you are flying on the ~Succubus Air Lines~ to <player>...",
			"Air Hostesses and their lashes are at your service during your trip!",
		},
		[3] = {
			"If you click on the portal, someone named <target> will appear and do your job for you!",
		},
		[4] = {
			"If you do not want a sprawling, phlegm-looking and asthmatic creature to come from this portal, click on it to help <target> find a path in Hell as quick as possible!",
		},
	};

	NECROSIS_SOULSTONE_ALERT_MESSAGE = {
		[1] = {
			"If you cherish the idea of a mass suicide, <target> now can self-resurrect, so all should be fine. Go ahead.",
		},
		[2]= {
			"<target> can go afk to drink a cup of coffee or so, soulstone is in place to allow for the wipe...",
		},
	};

	NECROSIS_PET_MESSAGE = {
		-- Imp
		[1] = {
			-- Summon speech 1
			[1] = {
				"Well, crappy nasty little Imp, now you stop sulking and you come to help! AND THAT'S AN ORDER!",
			},
			-- Summon speech 2
			[2] = {
				"<pet>! HEEL! NOW!",
			},
		};
		-- Voidwalker
		[2] = {
			-- Summon speech 1
			[1] = {
				-- First sentence in the chat window
				"Oops, I will probably need an idiot to be knocked for me...",
				-- Second sentence in the chat window
				"<pet>, please help!",
			},
		};
		-- Succubus
		[3] = {
			-- Summon speech 1
			[1] = {
				"<pet> baby, please help me sweet heart!",
			},
		};
		-- Felhunter
		[4] = {
			-- Summon speech 1
			[1] = {
				"<pet>! <pet>! Come on boy, come here! <pet>!",
			},
		};
		-- Sentences for the first summon: when Necrosis does not yet know your demon names
		[5] = {
			-- Summon speech 1
			[1] = {
				-- First sentence in the chat window
				"Fishing? Yes I love fishing... Look!",
				-- Second sentence in the chat window
				"I close my eyes, I move my fingers like that... And voila! Yes, yes, it is a fish, I swear!",
			},
			-- Summon speech 2
			[2] = {
				-- First sentence in the chat window
				"Anyway I hate you all! I don't need you, I have friends.... Powerful friends!",
				-- Second sentence in the chat window
				"COME TO ME, CREATURE OF HELL AND NIGHTMARE!",
			},
		};
		-- Sentences for the steed summon
		[6] = {
			-- Summon speech 1
			[1] = {
				-- First sentence in the chat window
				"Hey, I'm late! Let's find a horse that roxes!",
			},
			-- Summon speech 2
			[2] = {
				-- First sentence in the chat window
				"I am summoning a stead from a nightmare!",
				-- Second sentence in the chat window
				"AH AHA HA HA AH AH!",
			},
		};
	};
	
	NECROSIS_SHORT_MESSAGES = {
		{{"--> <target> is soulstoned for 30 minutes <--"}},
		{{"<TP> Summoning <target>, please click on the portal <TP>"}},
	};

end

-------------------------------------
--  FRENCH VERSION --
-------------------------------------

function Necrosis_Localization_Speech_Fr()

	NECROSIS_INVOCATION_MESSAGES = {
		[1] = {
			"Taxi des Arcanes ! J'invoque <target>, cliquez sur le portail svp !",
		},
		[2] = {
			"Bienvenue, <target>, sur le vol de ~Succube Air Lines~ \195\160 destination de <player>...",
			"Les h\195\180tesses et leur fouet sont \195\160 votre disposition durant le trajet",
		},
		[3] = {
			"Si vous ne voulez pas qu'une cr\195\169ature tentaculaire, glaireuse et asthmatique sorte de ce portail, cliquez dessus pour aider <target> \195\160 trouver son chemin au plus vite !",
		},
		[4] = {
			"Si vous cliquez sur le portail, un machin nomm\195\169 <target> sortira et fera le boulot \195\160 votre place...",
		},
		[5] = {
			"Tel un lapin dans un chapeau de mage, <target> va appara\195\174tre devant vos yeux \195\169bahis. Et hop.",
		},
		[6] = {
			"PAR ASTAROTH ET DASMODES, JE T'INVOQUE, O TOUT PUISSANT DEMON DES SEPTS ENFERS, PARANGON VELU DES INFRA MONDES DEMONIAQUES, PAR LA PUISSANCE DU SCEAU ANCESTR... euh ?!? Ah merde c’est <target> qui d\195\169barque !!",
		},
		[7] = {
			"Chantons ensemble ! Venu de nulle part, c'est <target>, Plus vif que le serpent, c'est <target> !",
			"Personne ne l'aper\195\167oit, c'est <target>, Mais il est toujours l\195\160, c'est <target> !",
			"Plein d'effroi les Pirates de Tanaris rien qu'\195\160 son nom voient leur sang qui se glace, se glace, se glace... Mais quand il y a danger, c'est <target> qui vient pour nous aider, <target>...",
			"(Cliquez vite sur le portail sinon je continue...)",
			"C'EST <target> ! <target> ! <target> !",
		},
	};

	NECROSIS_SOULSTONE_ALERT_MESSAGE = {
		[1] = {
			"Si ca vous tente un suicide collectif, <target> s'en fout, la pierre d'\195\162me lui permettra de se relever",
		},
		[2] = {
			"<target> peut partir siroter un caf\195\169, et pourra se relever du wipe qui s'en suivra gr\195\162ce \195\160 sa pierre d'\195\162me",
		},
		[3] = {
			"Pierre pos\195\169e sur <target>, vous pouvez recommencer \195\160 faire n’importe quoi sans risque",
		},
		[4] = {
			"Gr\195\162ce \195\160 sa pierre d’\195\162me, <target> est pass\195\169 en mode Easy wipe",
		},
		[5] = {
			"<target> peut d\195\169sormais revenir d’entre les morts, histoire d’organiser le prochain wipe",
		},
		[6] = {
			"Les hindous croient \195\160 l’immortalit\195\169, <target> aussi depuis que je lui ai pos\195\169 une pierre d’\195\162me",
		},
		[7] = {
			"<target> est d\195\169sormais \195\169quip\195\169 de son kit de survie temporaire.",
		},
		[8] = {
			"Tel le ph\195\169nix, <target> pourra revenir d’entre les flammes de l’enfer (Faut dire aussi qu’il a beaucoup de rf...)",
		},
		[9] = {
			"Gr\195\162ce \195\160 sa pierre d’\195\162me, <target> peut de nouveau faire n’importe quoi.",
		},
		[10] = {
			"Sur <target> poser une belle pierre d’\195\162me,",
			"Voil\195\160 qui peut ma foi \195\169viter bien des drames !",
		},
	};

	NECROSIS_PET_MESSAGE = {
		-- Imp
		[1] = {
			-- Random sentence 1
			[1] = {
				"Bon, s\195\162le petite peste de Diablotin, tu arr\195\170tes de bouder et tu viens m'aider ! ET C'EST UN ORDRE !",
			},
			-- Random sentence 2
			[2] = {
				"<pet> ! AU PIED ! TOUT DE SUITE !",
			},
			[3] = {
				"Attendez, je sors mon briquet !",
			},
		};
		-- Felhunter
		[2] = {
			-- Random sentence 1
			[1] = {
				-- First line in the chat window
				"Oups, je vais sans doute avoir besoin d'un idiot pour prendre les coups à ma place...",
				-- First line in the chat window
				"<pet>, viens m'aider !",
			},
			[2] = {
				"GRAOUbouhhhhh GROUAHOUhououhhaahpfffROUAH !",
				"GRAOUbouhhhhh GROUAHOUhououhhaahpfffROUAH !",
				"(Non je ne suis pas dingue, j'imite le bruit du marcheur en rut !)",
			},
		};
		-- Succubus
		[3] = {
			-- Random sentence 1
			[1] = {
				"<pet> ma grande, viens m'aider ch\195\169rie !",
			},
			[2] = {
				"Ch\195\169rie, l\195\162che ton rimmel et am\195\168ne ton fouet, y a du taf l\195\160 !",
			},
			[3] = {
				"<pet> ? Viens ici ma louloutte !",
			},
		};
		-- Felhunter
		[4] = {
			-- Random sentence 1
			[1] = {
				"<pet> ! <pet> ! Aller vient mon brave, viens ! <pet> !",
			},
			[2] = {
				"Rhoo, et qui c’est qui va se bouffer le mage hein ? C’est <pet> !",
				"Regardez, il bave d\195\169j\195\160 :)",
			},
			[3] = {
				"Une minute, je sors le caniche et j’arrive !",
			},
		};
		-- Sentence for the first pet summon (when Necrosis does not yet know its name)
		[5] = {
			-- Random sentence 1
			[1] = {
				-- First line in the chat window
				"La p\195\170che au d\195\169mon ? Rien de plus facile !",
				-- Second line in the chat window
				"Bon, je ferme les yeux, j'agite les doigts comme \195\167a... et hop ! Oh, les jolies couleurs !",
			},
			-- Random sentence 2
			[2] = {
				-- First line in the chat window
				"Toute fa\195\167on je vous d\195\169teste tous ! J'ai pas besoin de vous, j'ai des amis.... Puissants !",
				-- Second line in the chat window
				"VENEZ A MOI, CREATURES DE L'ENFER !",
			},
			-- Random sentence 3
			[3] = {
				-- First line in the chat window
				"Eh, le d\195\169mon, viens voir, il y a un truc \195\160 cogner l\195\160 !",
			},
			-- Random sentence 4
			[4] = {
				"En farfouillant dans le monde abyssal, on trouve de ces trucs... Regardez, ceci par exemple !",
			},
				
		};
		-- Sentences for the steed summon
		[6] = {
			-- Random sentence 1
			[1] = {
				"Mmmphhhh, je suis en retard ! Invoquons vite un cheval qui rox !",
			},
			-- Random sentence 2
			[2] = {
				"J'invoque une monture de l'enfer !",
			},
			[3] = {
				"MOUHAhaHAAHAhaHAhAHAahAaHAAHaHAhaHAaaAahAHa !",
				"TREMBLEZ, MORTELS, J'ARRIVE A LA VITESSE DU CAUCHEMARD !!!!",
			},
			[4] = {
				"Et hop, un cheval tout feu tout flamme !",
			},
			[5] = {
				"Vous savez, depuis que j’ai mis une selle ignifug\195\169e, je n'ai plus de probl\195\168me de culotte !"
			},
		};
	};

	NECROSIS_SHORT_MESSAGES = {
		{{"--> <target> est prot\195\169g\195\169 par une pierre d'\195\162me <--"}},
		{{"<TP> Invocation de <target> en cours, cliquez sur le portail svp <TP>"}}
	};

end



-------------------------------------
--  GERMAN VERSION --
-------------------------------------

function Necrosis_Localization_Speech_De()

	NECROSIS_INVOCATION_MESSAGES = {
		[1] = {
			"Arcanum Taxi Cab! Ich beschw\195\182re <target>, bitte klicke auf das Portal.",
		},
		[2] = {
			"Willkommen an Bord, <target>, du fliegst mit ~Sukkubus Air Lines~ zu <player>...",
			"Die Stewardessen und ihre Peitschen werden Dir w\195\164hrend der Reise zur Verf\195\188gung stehen!",
		},
		[3] = {
			"Wenn Du das Portal klicken w\195\188rdest, wird jemand mit dem Namen <target> erscheinen, und Deinen Job f\195\188r Dich tun!",
		},
		[4] = {
			"Wenn Du nicht m\195\182chtest, dass eine auf dem Boden kriechende, schleimige und einfach gr\195\164ssliche Kreatur aus diesem Portal kommt,",
			"klicke drauf und hilf <target>, so schnell wie m\195\182glich einen Weg zur H\195\182lle zu finden!",
		},
	};

	NECROSIS_SOULSTONE_ALERT_MESSAGE = {
		[1] = {
			"Solltet Ihr einen Massenselbstmord erw\195\164gen, denkt daran dass <target> sich nun selbst wiederbeleben kann. Alles wird gut werden, auf in den Kampf!",
		},
		[2] = {
			"<target> kann afk gehen um eine Tasse Kaffee oder so zu trinken, denn er wird Dank dieses Seelensteins in der Lage sein, unseren Tod zu \195\188berleben",
		},
};

	
	NECROSIS_SHORT_MESSAGES = {
		{{"--> <target> hat nun einen Seelenstein aktiv f\195\188r 30 Minuten <--"}},
		{{"<Portal> Ich beschw\195\182re <target>, bitte klickt auf das Tor <Portal>"}}
	};

	NECROSIS_PET_MESSAGE = {
		-- Imp
		[1] = {
			-- Summoning speech 1
			[1] = {
				"Na mein kleiner, b\195\182ser Wichtel, nun h\195\182r auf rumzuzicken und hilf endlich! UND DAS IST EIN BEFEHL!",
			},
			-- Summoning speech 2
			[2] = {
				"<pet>! SCHWING DIE BEINE! JETZT SOFORT!",
			},
		};
		-- Voidwalker
		[2] = {
			-- Summoning speech 1
			[1] = {
				-- First sentence in the chat window
				"Huuuch, anscheinend brauch ich einen Idioten, der f\195\188r mich die R\195\188be hinh\195\164lt...",
				-- Second sentence in the chat window
				"<pet>, hilf mir!",
			},
		};
		-- Succubus
		[3] = {
			-- Summoning speech 1
			[1] = {
				"<pet>, Baby, sei ein Schatzi und hilf mir!",
			},
		};
		-- Felhunter
		[4] = {
			-- Summoning speech 1
			[1] = {
				"<pet>! <pet>! Bei Fu\195\159, mein Guter, bei Fu\195\159! <pet>!",
			},
		};
		-- Sentences for the first summon: when Necrosis does not know your demon's name
		[5] = {
			-- Summoning speech 1
			[1] = {
				-- First sentence in the chat window
				"Angeln ? Oh jaaa, ich liebe Angeln, schau!",
				-- Second sentence in the chat window
				"Ich schlie\195\159e meine Augen, dann bewege ich meine Finger in etwa so... Und voila! Ja, aber sicher, es ist ein Fisch, ich schw\195\182re es Dir!",
			},
			-- Summoning speech 2
			[2] = {
				-- First sentence in the chat window
				"Nichtsdestotrotz hasse ich Euch alle! Ich brauche Euch nicht, ich habe Freunde.... M\195\164chtige Freunde!",
				-- Second sentence in the chat window
				"KOMM ZU MIR, KREATUR, DIE DU KOMMST AUS DER H\195\150LLE UND ENDLOSEN ALPTR\195\132UMEN!",
			},
		};
		-- Summoning speeches for the mount
		[6] = {
			-- Summoning speech 1
			[1] = {
				-- First sentence in the chat window
				"Hey, ich bin sp\195\164t dran! Ich hoffe ich finde ein Pferd das rennt wie ein ge\195\182lter Blitz!",
			},
			-- Summoning speech 2
			[2] = {
				-- First sentence in the chat window
				"Ich beschw\195\182re ein Reittier, das einem Alptraum entspringt!",
				-- Second sentence in the chat window
				"AH AHA HA HA AH AH!",
			},
		};
	};

end


-- For special characters:
-- Special characters:
-- e acute = \195\169 ---- e grave = \195\168
-- a grave = \195\160 ---- a circumflex = \195\162
-- o circumflex = \195\180 ---- e circumflex = \195\170
-- u circumflex = \195\187 ---- a umlaut = \195\164
-- A umlaut = \195\132 ---- o umlaut = \195\182
-- O umlaut = \195\150 ---- u umlaut = \195\188
-- U umlaut = \195\156 ---- sharp s = \195\159
-- c cedilla = \195\167 ---- i circumflex = \195\174