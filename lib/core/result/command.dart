import 'package:flutter/foundation.dart';

import 'result.dart';

enum CommandState { idle, running, success, failure }

class Command0<Output> extends ChangeNotifier {
  Command0(this._action);

  final Future<Result<Output>> Function() _action;

  CommandState _state = CommandState.idle;
  Result<Output>? _result;

  CommandState get state => _state;
  Result<Output>? get result => _result;

  Future<Result<Output>> execute() async {
    _state = CommandState.running;
    notifyListeners();

    final result = await _action();
    _result = result;
    _state = result is Success<Output>
        ? CommandState.success
        : CommandState.failure;
    notifyListeners();
    return result;
  }
}

class Command1<Output, Input> extends ChangeNotifier {
  Command1(this._action);

  final Future<Result<Output>> Function(Input input) _action;

  CommandState _state = CommandState.idle;
  Result<Output>? _result;

  CommandState get state => _state;
  Result<Output>? get result => _result;

  Future<Result<Output>> execute(Input input) async {
    _state = CommandState.running;
    notifyListeners();

    final result = await _action(input);
    _result = result;
    _state = result is Success<Output>
        ? CommandState.success
        : CommandState.failure;
    notifyListeners();
    return result;
  }
}
