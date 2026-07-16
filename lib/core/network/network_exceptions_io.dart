import 'dart:io';

bool isSocketLikeException(Object error) {
  return error is SocketException || error is HandshakeException;
}

