NoteMidi = ba.midikey2hz(hslider("Note", 50, 30, 70, 1));
GateMidi = checkbox("Gate");

/*	Petit tour des modules

*	additive(<id>, <Frequence>, <nb d'oschilateur>) :
	Module de synth additive à partir de Sinus.
	Le nombre d'oscilateur ne peut pas varier dans le temps

*	complexOsc(<id>, <Frequence>, <type de l'oscilateur>)
	Le type d'oscilateur est un nombre entre 0 et 4 qui permet de passer de
	0 - Sinus
	1 - triangle
	2 - Dent de scie
	3 - Onde carré
	4 - bruit

* 	fmSynth(<id>, <Frequence>, <Ratio>, <Amplitude de la modulation>)
	Un module de synthère FM simple

* 	filter(<id>, <cutoff>, <resonance>, <type de filtre>)
	Le type de filtre est un nombre entre 0 et 2 qui permet de passer de :
	0 - passe bas
	1 - passe bande
	2 - passe haut

* 	enveloppe(<id>, <attaque>, <decay>, <release>, <trigger>)
	Les paramètre d'attaque, decay, sustain, release sont indiqués en secondes
	Le sustain doit être entre 0 et 1
	Le trigger est soit 1 soit 0

* Créer un slider :
	vslider(<nom du slider entre ">, <valeur initiale>, <valeur minimum>, <valeur max>, <pas du slider>)
*/

// Faite votre montage dans la formule "process"

process =
  complexOsc(0, NoteMidi, 2) :
  filter(0, hslider("cutoff", 100, 50, 10000, 1), hslider("res", 1, 0.5, 10, 0.01), 0) :
  *(enveloppe(1, GateMidi)):
  *(hslider("MAIN VOLUME", 0, 0, 1, 0.01)) <:_,_; // Toujours garder cette dernière ligne

///// ICI ON FAIT DU CODE ////
import("stdfaust.lib");

additive(id, freq, nbOsc) =
  hgroup("AdditivSynth %id",
  	hgroup("Freq", par(i, nbOsc, os.oscsin(freq*vslider("Freq %i [style : knobs]", i+1, 1, 16, 0.01)) * 1/10)) :
  	hgroup("Amp", par(i, nbOsc, *(vslider("Amp %i [style : knobs]", 1-i/nbOsc, 0, 1, 0.001))))
  ) :> _;

complexOsc(id, freq, typeOsc) =
  hgroup("CompOsc %id",
	os.oscsin(freq) * max(0, 1-typeOsc),
	os.triangle(freq) * scale(typeOsc, 2),
	os.sawtooth(freq) * scale(typeOsc, 3),
	os.square(freq) * scale(typeOsc, 4),
	(no.noise : ba.sAndH(@(os.phasor(ma.SR, freq),1 ) > os.phasor(ma.SR, freq)) :  *(scale(typeOsc, 5))) :> *(0.5));

fmOsc(id, freq, ratio, amp) =
  hgroup("FMSynth %id",
	(freq*ratio <:os.oscsin, *(amp) : *) : +(freq) : os.oscsin :*(0.5)
  );

enveloppe(id, t) = hgroup("envellope %id",
  en.adsr(
  	vslider("[0]Attack", 0.02, 0.01, 1, 0.001),
  	vslider("[1]Decay", 0.02, 0.01, 1, 0.001),
  	vslider("[2]Sustain", 0.5, 0., 1., 0.01),
  	vslider("[3]Release", 0.02, 0.01, 1, 0.001),
  	t));

filter(id, cutoff, res, typeFi) =
  hgroup("Filter %id",
	_ <:
  	fi.resonlp(cutoff, res, 0.5) * scale(typeFi, 1),
  	fi.resonbp(cutoff, res, 0.5) * scale(typeFi, 2),
  	fi.resonhp(cutoff, res, 0.5) * scale(typeFi, 3)
	:> _);

scale(_x, _max) =
  max(0, 1-abs(_x - (_max-1)));
