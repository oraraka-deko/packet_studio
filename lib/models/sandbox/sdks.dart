import 'dart:io';

import 'package:studio_packet/models/sandbox/enums.dart';

class SDKs {

  final Platform platform;
  final String path;
  SetupStatus setupStatus;
  SDKs({
    required this.platform,
    required this.path,
    this.setupStatus = SetupStatus.notStarted,
  });}