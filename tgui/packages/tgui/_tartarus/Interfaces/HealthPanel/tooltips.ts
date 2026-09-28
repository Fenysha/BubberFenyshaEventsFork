export const TOOLTIPS = {
  // Vitals
  consciousness:
    'How awake and aware you are (0–100). Low values slow you down, impair control, and can cause unconsciousness.',
  pain: 'Total pain from injuries. High pain increases shock, slows movement, can make you drop items, and may knock you out.',
  shock:
    'Physiological shock from pain and blood loss. Builds under stress and reduces consciousness. Recovers slowly when the cause is gone.',
  heartbeat:
    'Heart rate (bpm) and rhythm. Abnormal rhythms (arrhythmia, fibrillation, asystole) indicate serious cardiac problems.',
  breathing:
    'Respiratory rate and effectiveness. Impaired breathing reduces oxygenation and can lead to suffocation.',
  bleedRate:
    'Total blood loss per second from all injuries. High bleed rate causes shock and eventual death if untreated.',
  movement:
    'Whether you can stand and walk. Affected by leg injuries, pain, shock, and consciousness.',

  // Lungs
  lungsPanel:
    'Left and right lung status. Blood or fluid fill reduces capacity. A collapsed lung (pneumothorax) severely impairs breathing.',
  lungCollapsed:
    'This lung has collapsed (pneumothorax). Requires urgent treatment.',
  lungBlood: 'Blood is filling this lung, reducing oxygen exchange.',
  lungFluid: 'Fluid is filling this lung. Breathing efficiency is reduced.',
  lungOk: 'This lung is clear and functional.',

  // Cardiogram
  cardiogram:
    'Live ECG-style trace. Pattern changes with rhythm disorders. Flatline means no electrical activity (asystole).',

  // Body
  bodyDoll: 'Select a body part or organ to inspect details on the right.',
  limbMissing: 'This limb is absent.',
  limbDisabled:
    'This limb cannot be used (paralysis, severe injury, or similar).',
  limbBrute: 'Physical trauma on this limb.',
  limbBurn: 'Burn damage on this limb.',
  limbBleeding: 'Blood loss rate from this limb.',

  // Organs
  organBrain:
    'Central nervous system. Damage affects consciousness, control, and survival.',
  organHeart:
    'Pumps blood. Failure or stoppage leads to rapid death without intervention.',
  organLungs:
    'Gas exchange. Failure causes suffocation even if the airway is clear.',
  organFailing: 'This organ is failing and not performing adequately.',
  organMissing: 'This organ is absent.',

  // Injuries
  injuryList: 'Active medical conditions on the selected limb.',
  injuryDisabling: 'This injury prevents normal use of the limb.',
  injuryBleed: 'Blood loss contributed by this injury.',

  // General
  close: 'Close the health panel.',
  selectHint: 'Select a body part or organ in the center to inspect it here.',
} as const;
