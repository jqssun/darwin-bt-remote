import Foundation

public enum SDPRecord {
    static func buildHID(_ identity: HIDIdentity) -> [String: Any] {
        let common: [String: Any] = [
            "0000 - ServiceRecordHandle": 65536 as NSNumber,
            "0001 - ServiceClassIDList": [
                uuid16(0x1124)
            ],

            "0004 - ProtocolDescriptorList": [
                [
                    uuid16(0x0100),
                    uint(0x0011, bytes: 2)
                ],
                [
                    uuid16(0x0011)
                ]
            ],

            "0006 - LanguageBaseAttributeIDList": [
                uint(0x656E, bytes: 2),
                uint(0x006A, bytes: 2),
                uint(0x0100, bytes: 2)
            ],

            "000D - AdditionalProtocolDList": [
                [
                    [
                        uuid16(0x0100),
                        uint(0x0013, bytes: 2)
                    ],
                    [
                        uuid16(0x0011)
                    ]
                ]
            ],

            "0201 - HIDParserVersion": uint(0x0111, bytes: 2),
            "0204 - HIDVirtualCable": true,
            "0205 - HIDReconnectInitiate": true,

            "0206 - HIDDescriptorList": [
                [
                    uint(0x22, bytes: 1),
                    text(identity.reportMap)
                ]
            ],

            "0209 - HIDBatteryPower": true,
            "020A - HIDRemoteWake": true,
            "020B - HIDProfileVersion": uint(0x0100, bytes: 2),
            "020C - HIDSupervisionTimeout": uint(0x1F40, bytes: 2)
        ]
        return common.merging(identity.sdp) { $1 }
    }

    static func buildDeviceID(_ pnp: PnPID) -> [String: Any] {
        [
            "0000 - ServiceRecordHandle": 65537 as NSNumber,
            "0001 - ServiceClassIDList": [
                uuid16(0x1200)
            ],

            "0004 - ProtocolDescriptorList": [
                [
                    uuid16(0x0100),
                    uint(0x0001, bytes: 2)
                ],
                [
                    uuid16(0x0001)
                ]
            ],

            "0009 - BluetoothProfileDescriptorList": [
                [
                    uuid16(0x1200),
                    uint(0x0103, bytes: 2)
                ]
            ],

            "0200 - SpecificationID": uint(0x0103, bytes: 2),
            "0201 - VendorID": uint(UInt32(pnp.vendor), bytes: 2),
            "0202 - ProductID": uint(UInt32(pnp.product), bytes: 2),
            "0203 - Version": uint(UInt32(pnp.version), bytes: 2),
            "0204 - PrimaryRecord": true,
            "0205 - VendorIDSource": uint(UInt32(pnp.source), bytes: 2)
        ]
    }

    public static func uint(_ value: UInt32, bytes: Int) -> [String: Any] {
        var data = Data()
        switch bytes {
        case 1: data.append(UInt8(value & 0xFF))
        case 2: data.append(contentsOf: [UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)])
        case 4: data.append(contentsOf: [
                UInt8((value >> 24) & 0xFF),
                UInt8((value >> 16) & 0xFF),
                UInt8((value >> 8) & 0xFF),
                UInt8(value & 0xFF)
            ])
        default: fatalError("unsupported uint byteCount")
        }
        return [
            "DataElementSize": 0,
            "DataElementType": 1,
            "DataElementValue": data
        ]
    }

    public static func uuid16(_ value: UInt16) -> Data {
        Data([UInt8(value >> 8), UInt8(value & 0xFF)])
    }

    private static func text(_ bytes: Data) -> [String: Any] {
        [
            "DataElementType": 4,
            "DataElementValue": bytes
        ]
    }
}
