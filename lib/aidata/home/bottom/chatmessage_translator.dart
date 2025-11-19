part of '../home.dart';

class MovieTvTranslator {


  MovieTvTranslator() ;


  final client = openai.OpenAIClient(
    apiKey: Cfg.current.key,
    baseUrl: Cfg.current.url,
  );

Future<String> mainTreanslator(String text) async {
  final targetLanguage = Cfg.current.defaultTranslateLanguage ?? 'English';

  return "";}}