/*
 *
 * Copyright 2016, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
import Foundation

func zigzag(_ n:Int32) -> (Int32) {
  return (n << 1) ^ (n >> 31)
}

func zigzag(_ n:Int64) -> (Int64) {
  return (n << 1) ^ (n >> 63)
}

public class Message {
  var descriptor: MessageDescriptor
  var fields: [Field]

  init(descriptor: MessageDescriptor, fields: [Field]) {
    self.descriptor = descriptor
    self.fields = fields
  }

  public func addField(name: String, action:((Field) -> Void)) {
    // look up the field descriptor
    for fieldDescriptor in descriptor.fieldDescriptors {
      if (fieldDescriptor.name == name) {
        // create a field with that descriptor
        let field = Field(descriptor:fieldDescriptor)
        // add it to self.fields
        self.fields.append(field)
        action(field)
      }
    }
  }

  public func oneField(name: String) -> Field? {
    for field in fields {
      if field.name() == name {
        return field
      }
    }
    return nil
  }

  public func forOneField(name: String, action:((Field) -> Void)) {
    for field in fields {
      if field.name() == name {
        action(field)
        break
      }
    }
  }

  public func forEachField(name:String, action:(Field) -> (Void)) {
    for field in fields {
      if field.name() == name {
        action(field)
      }
    }
  }

  public func forEachField(path:[String], action:(Field) -> (Void)) {
    for field in fields {
      if field.name() == path[0] {
        if path.count == 1 {
          action(field)
        } else {
          var subpath = path
          subpath.removeFirst()
          field.message().forEachField(path:subpath, action:action)
        }
      }
    }
  }

  public func display() {
    for field in fields {
      field.display(indent:"")
    }
  }

  public func serialize() -> (NSMutableData) {
    let data = NSMutableData()
    for field in fields {
      data.appendVarint(field.tag() << 3 + field.wireType())

      switch field.type() {
      case FieldType.DOUBLE:
        data.appendDouble(field.double())
      case FieldType.FLOAT:
        data.appendFloat(field.float())
      case FieldType.INT64:
        data.appendVarint(field.integer())
      case FieldType.UINT64:
        data.appendVarint(field.integer())
      case FieldType.INT32:
        data.appendVarint(field.integer())
      case FieldType.FIXED64:
        data.appendInt64(field.integer())
      case FieldType.FIXED32:
        data.appendInt32(field.integer())
      case FieldType.BOOL:
        data.appendVarint(field.bool() ? 1 : 0)
      case FieldType.STRING:
        var buf = [UInt8](field.string().utf8)
        data.appendVarint(buf.count)
        data.append(&buf, length: buf.count)
      case FieldType.GROUP:
        assert(false)
      case FieldType.MESSAGE:
        let messageData = field.message().serialize()
        data.appendVarint(messageData.length)
        data.append(messageData as Data)
      case FieldType.BYTES:
        let messageData = field.data()
        data.appendVarint(messageData.length)
        data.append(messageData as Data)
      case FieldType.UINT32:
        data.appendVarint(field.integer())
      case FieldType.ENUM:
        assert(false)
      case FieldType.SFIXED32:
        data.appendInt32(field.integer())
      case FieldType.SFIXED64:
        data.appendInt64(field.integer())
      case FieldType.SINT32:
        data.appendVarint(Int(zigzag(Int32(field.integer()))))
      case FieldType.SINT64:
        data.appendVarint(Int(zigzag(Int64(field.integer()))))
      }
    }
    return data
  }
  
}
