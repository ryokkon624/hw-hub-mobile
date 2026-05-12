enum ProgramType {
  system('SYSTEM'),
  admin('ADMIN'),
  onlAuth('OnlAuth'),
  onlCode('OnlCode'),
  onlHldauth('OnlHldAuth'),
  onlHldinvi('OnlHldInvi'),
  onlHldmem('OnlHldMem'),
  onlHld('OnlHld'),
  onlHwr('OnlHwr'),
  onlHwrtsk('OnlHwrTsk'),
  onlShpatch('OnlShpAtch'),
  onlShp('OnlShp'),
  onlUsricon('OnlUsrIcon'),
  onlUsr('OnlUsr'),
  onlPwdrst('OnlPwdRst'),
  onlAuthGoogle('OnlAuthGgl'),
  onlNtfQry('OnlNtfQry'),
  onlInqry('OnlInqry'),
  onlUsrRole('OnlUsrRole'),
  onlAdmInq('OnlAdmInq'),
  onlAdmUsr('OnlAdmUsr'),
  onlAdmHwTp('OnlAdmHwTp'),
  onlAdmAnn('OnlAdmAnn'),
  btcInvExpr('BtcInvExpr'),
  btcTskGen('BtcTskGen'),
  btcTskRecl('BtcTskRecl'),
  btcHldClen('BtcHldClen'),
  btcNtfAggr('BtcNtfAggr'),
  btcInqAi('BtcInqAI');

  const ProgramType(this.code);
  final String code;

  static ProgramType? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
