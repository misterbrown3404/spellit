bool isSocketLikeException(Object error) {
  final typeName = error.runtimeType.toString();
  return typeName == 'SocketException' || typeName == 'HandshakeException';
}

