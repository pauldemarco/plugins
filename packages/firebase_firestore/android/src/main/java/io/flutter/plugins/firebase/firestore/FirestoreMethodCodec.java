// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.firebase.firestore;

import io.flutter.plugins.firebase.firestore.FirestoreMessageCodec.ExposedByteArrayOutputStream;
import io.flutter.plugin.common.*;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * A {@link MethodCodec} using the Flutter standard binary encoding.
 *
 * <p>This codec is guaranteed to be compatible with the corresponding
 * <a href="https://docs.flutter.io/flutter/services/FirestoreMethodCodec-class.html">FirestoreMethodCodec</a>
 * on the Dart side. These parts of the Flutter SDK are evolved synchronously.</p>
 *
 * <p>Values supported as method arguments and result payloads are those supported by
 * {@link FirestoreMessageCodec}.</p>
 */
public final class FirestoreMethodCodec implements MethodCodec {
    public static final FirestoreMethodCodec INSTANCE = new FirestoreMethodCodec();

    private FirestoreMethodCodec() {
    }

    @Override
    public ByteBuffer encodeMethodCall(MethodCall methodCall) {
        final ExposedByteArrayOutputStream stream = new ExposedByteArrayOutputStream();
        FirestoreMessageCodec.writeValue(stream, methodCall.method);
        FirestoreMessageCodec.writeValue(stream, methodCall.arguments);
        final ByteBuffer buffer = ByteBuffer.allocateDirect(stream.size());
        buffer.put(stream.buffer(), 0, stream.size());
        return buffer;
    }

    @Override
    public MethodCall decodeMethodCall(ByteBuffer methodCall) {
        methodCall.order(ByteOrder.nativeOrder());
        final Object method = FirestoreMessageCodec.readValue(methodCall);
        final Object arguments = FirestoreMessageCodec.readValue(methodCall);
        if (method instanceof String && !methodCall.hasRemaining()) {
            return new MethodCall((String) method, arguments);
        }
        throw new IllegalArgumentException("Method call corrupted");
    }

    @Override
    public ByteBuffer encodeSuccessEnvelope(Object result) {
        final ExposedByteArrayOutputStream stream = new ExposedByteArrayOutputStream();
        stream.write(0);
        FirestoreMessageCodec.writeValue(stream, result);
        final ByteBuffer buffer = ByteBuffer.allocateDirect(stream.size());
        buffer.put(stream.buffer(), 0, stream.size());
        return buffer;
    }

    @Override
    public ByteBuffer encodeErrorEnvelope(String errorCode, String errorMessage,
                                          Object errorDetails) {
        final ExposedByteArrayOutputStream stream = new ExposedByteArrayOutputStream();
        stream.write(1);
        FirestoreMessageCodec.writeValue(stream, errorCode);
        FirestoreMessageCodec.writeValue(stream, errorMessage);
        FirestoreMessageCodec.writeValue(stream, errorDetails);
        final ByteBuffer buffer = ByteBuffer.allocateDirect(stream.size());
        buffer.put(stream.buffer(), 0, stream.size());
        return buffer;
    }

    @Override
    public Object decodeEnvelope(ByteBuffer envelope) {
        envelope.order(ByteOrder.nativeOrder());
        final byte flag = envelope.get();
        switch (flag) {
            case 0: {
                final Object result = FirestoreMessageCodec.readValue(envelope);
                if (!envelope.hasRemaining()) {
                    return result;
                }
            }
            case 1: {
                final Object code = FirestoreMessageCodec.readValue(envelope);
                final Object message = FirestoreMessageCodec.readValue(envelope);
                final Object details = FirestoreMessageCodec.readValue(envelope);
                if (code instanceof String
                        && (message == null || message instanceof String)
                        && !envelope.hasRemaining()) {
                    throw new FlutterException((String) code, (String) message, details);
                }
            }
        }
        throw new IllegalArgumentException("Envelope corrupted");
    }
}