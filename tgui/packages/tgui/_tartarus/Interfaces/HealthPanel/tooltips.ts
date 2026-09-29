export const TOOLTIPS = {
  consciousness:
    'Current level of wakefulness and awareness. Severe hypoperfusion, hypoxia, shock, or pain can drive it toward unconsciousness.',
  pain: 'Current acute and injury-derived pain. Persistent pain contributes to shock and impaired consciousness.',
  shock:
    'Systemic physiological stress caused by pain, hemorrhage, and poor circulation. Higher values impair consciousness and recovery.',
  heartbeat:
    'Current pulse and rhythm. Cardiac output depends on heart rate, myocardial contractility, and stroke efficiency.',
  cardiacOutput:
    'Relative cardiac output. It determines how effectively the heart supplies systemic circulation.',
  bloodPressure:
    'Current systemic blood pressure derived from cardiac output and circulating blood volume.',
  perfusion:
    'Relative cerebral perfusion derived from blood pressure. Low perfusion reduces brain oxygen delivery.',
  bloodVolume:
    'Current circulating blood volume relative to normal. Major blood loss lowers pressure and organ perfusion.',
  breathing:
    'Whether ventilation is currently effective. Failed or impaired breaths reduce blood oxygenation.',
  oxygenation: 'Current blood oxygenation produced by the respiratory system.',
  ventilation:
    'Effective lung ventilation after accounting for lung damage and fluid accumulation.',
  bleedRate:
    'Current blood loss per second from active injuries. Arterial bleeding is strongly affected by blood pressure and cardiac pulse.',
  lungFluid:
    'Fluid accumulation in the lungs. Higher levels reduce effective ventilation and oxygen exchange.',
  cardiogram:
    'Live ECG-style trace generated from the current heart rhythm. A flatline represents asystole.',

  bodyDoll: 'Select a body part or organ to inspect its current condition.',
  limbMissing: 'This body part is absent.',
  limbDisabled:
    'This body part cannot be used because of severe injury or disability.',
  limbStructure:
    'Remaining structural integrity of muscle, connective tissue, bone, and other physical structures.',
  limbSkin:
    'Remaining integrity of the skin and superficial protective tissue.',
  limbBleeding: 'Current blood loss rate originating from this body part.',

  organBrain:
    'Central nervous system. Brain oxygen and blood perfusion directly affect consciousness and survival.',
  brainOxygen:
    'Current oxygen reserve of the brain. Persistent severe hypoxia causes irreversible brain damage.',
  organHeart:
    'The heart determines pulse, cardiac output, and systemic blood pressure. Failure or asystole rapidly eliminates cerebral perfusion.',
  organLungs:
    'The lungs determine ventilation and blood oxygenation. Damage or fluid accumulation reduces oxygen delivery.',
  organFailing:
    'This organ is failing and is no longer performing at full capacity.',
  organMissing: 'This organ is absent.',

  injuryList: 'Active medical conditions affecting the selected body part.',
  injuryDisabling: 'This injury prevents normal use of the body part.',
  injuryBleed: 'Blood loss currently contributed by this injury.',

  close: 'Close the health panel.',
  selectHint:
    'Select a body part or organ in the center to inspect its detailed state.',
} as const;
