//
//  MultipartFormDataTests.swift
//
//  Copyright (c) 2014-2016 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Alamofire
import Foundation
import XCTest

private struct TestCertificates {
    // Root Certificates
    static let RootCA = TestCertificates.certificateWithFileName("alamofire-root-ca")

    // Intermediate Certificates
    static let IntermediateCA1 = TestCertificates.certificateWithFileName("alamofire-signing-ca1")
    static let IntermediateCA2 = TestCertificates.certificateWithFileName("alamofire-signing-ca2")

    // Leaf Certificates - Signed by CA1
    static let LeafWildcard = TestCertificates.certificateWithFileName("wildcard.alamofire.org")
    static let LeafMultipleDNSNames = TestCertificates.certificateWithFileName("multiple-dns-names")
    static let LeafSignedByCA1 = TestCertificates.certificateWithFileName("signed-by-ca1")
    static let LeafDNSNameAndURI = TestCertificates.certificateWithFileName("test.alamofire.org")

    // Leaf Certificates - Signed by CA2
    static let LeafExpired = TestCertificates.certificateWithFileName("expired")
    static let LeafMissingDNSNameAndURI = TestCertificates.certificateWithFileName("missing-dns-name-and-uri")
    static let LeafSignedByCA2 = TestCertificates.certificateWithFileName("signed-by-ca2")
    static let LeafValidDNSName = TestCertificates.certificateWithFileName("valid-dns-name")
    static let LeafValidURI = TestCertificates.certificateWithFileName("valid-uri")

    static func certificateWithFileName(_ fileName: String) -> SecCertificate {
        class Bundle {}
        let filePath = Foundation.Bundle(for: Bundle.self).pathForResource(fileName, ofType: "cer")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        let certificate = SecCertificateCreateWithData(nil, data)!

        return certificate
    }
}

// MARK: -

private struct TestPublicKeys {
    // Root Public Keys
    static let RootCA = TestPublicKeys.publicKeyForCertificate(TestCertificates.RootCA)

    // Intermediate Public Keys
    static let IntermediateCA1 = TestPublicKeys.publicKeyForCertificate(TestCertificates.IntermediateCA1)
    static let IntermediateCA2 = TestPublicKeys.publicKeyForCertificate(TestCertificates.IntermediateCA2)

    // Leaf Public Keys - Signed by CA1
    static let LeafWildcard = TestPublicKeys.publicKeyForCertificate(TestCertificates.LeafWildcard)
    static let LeafMultipleDNSNames = TestPublicKeys.publicKeyForCertificate(TestCertificates.LeafMultipleDNSNames)
    static let LeafSignedByCA1 = TestPublicKeys.publicKeyForCertificate(TestCertificates.LeafSignedByCA1)
    static let LeafDNSNameAndURI = TestPublicKeys.publicKeyForCertificate(TestCertificates.LeafDNSNameAndURI)

    // Leaf Public Keys - Signed by CA2
    static let LeafExpired = TestPublicKeys.publicKeyForCertificate(TestCertificates.LeafExpired)
    static let LeafMissingDNSNameAndURI = TestPublicKeys.publicKeyForCertificate(TestCertificates.LeafMissingDNSNameAndURI)
    static let LeafSignedByCA2 = TestPublicKeys.publicKeyForCertificate(TestCertificates.LeafSignedByCA2)
    static let LeafValidDNSName = TestPublicKeys.publicKeyForCertificate(TestCertificates.LeafValidDNSName)
    static let LeafValidURI = TestPublicKeys.publicKeyForCertificate(TestCertificates.LeafValidURI)

    static func publicKeyForCertificate(_ certificate: SecCertificate) -> SecKey {
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        SecTrustCreateWithCertificates(certificate, policy, &trust)

        let publicKey = SecTrustCopyPublicKey(trust!)!

        return publicKey
    }
}

// MARK: -

private enum TestTrusts {
    // Leaf Trusts - Signed by CA1
    case leafWildcard
    case leafMultipleDNSNames
    case leafSignedByCA1
    case leafDNSNameAndURI

    // Leaf Trusts - Signed by CA2
    case leafExpired
    case leafMissingDNSNameAndURI
    case leafSignedByCA2
    case leafValidDNSName
    case leafValidURI

    // Invalid Trusts
    case leafValidDNSNameMissingIntermediate
    case leafValidDNSNameWithIncorrectIntermediate

    var trust: SecTrust {
        let trust: SecTrust

        switch self {
        case .leafWildcard:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.LeafWildcard,
                TestCertificates.IntermediateCA1,
                TestCertificates.RootCA
            ])
        case .leafMultipleDNSNames:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.LeafMultipleDNSNames,
                TestCertificates.IntermediateCA1,
                TestCertificates.RootCA
            ])
        case .leafSignedByCA1:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.LeafSignedByCA1,
                TestCertificates.IntermediateCA1,
                TestCertificates.RootCA
            ])
        case .leafDNSNameAndURI:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.LeafDNSNameAndURI,
                TestCertificates.IntermediateCA1,
                TestCertificates.RootCA
            ])
        case .leafExpired:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.LeafExpired,
                TestCertificates.IntermediateCA2,
                TestCertificates.RootCA
            ])
        case .leafMissingDNSNameAndURI:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.LeafMissingDNSNameAndURI,
                TestCertificates.IntermediateCA2,
                TestCertificates.RootCA
            ])
        case .leafSignedByCA2:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.LeafSignedByCA2,
                TestCertificates.IntermediateCA2,
                TestCertificates.RootCA
            ])
        case .leafValidDNSName:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.LeafValidDNSName,
                TestCertificates.IntermediateCA2,
                TestCertificates.RootCA
            ])
        case .leafValidURI:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.LeafValidURI,
                TestCertificates.IntermediateCA2,
                TestCertificates.RootCA
            ])
        case leafValidDNSNameMissingIntermediate:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.LeafValidDNSName,
                TestCertificates.RootCA
            ])
        case leafValidDNSNameWithIncorrectIntermediate:
            trust = TestTrusts.trustWithCertificates([
                TestCertificates.LeafValidDNSName,
                TestCertificates.IntermediateCA1,
                TestCertificates.RootCA
            ])
        }

        return trust
    }

    static func trustWithCertificates(_ certificates: [SecCertificate]) -> SecTrust {
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        SecTrustCreateWithCertificates(certificates, policy, &trust)

        return trust!
    }
}

// MARK: - Basic X509 and SSL Exploration Tests -

class ServerTrustPolicyTestCase: BaseTestCase {
    func setRootCertificateAsLoneAnchorCertificateForTrust(_ trust: SecTrust) {
        SecTrustSetAnchorCertificates(trust, [TestCertificates.RootCA])
        SecTrustSetAnchorCertificatesOnly(trust, true)
    }

    func trustIsValid(_ trust: SecTrust) -> Bool {
        var isValid = false

        var result = SecTrustResultType.invalid
        let status = SecTrustEvaluate(trust, &result)

        if status == errSecSuccess {
            let unspecified = SecTrustResultType.unspecified
            let proceed = SecTrustResultType.proceed

            isValid = result == unspecified || result == proceed
        }

        return isValid
    }
}

// MARK: -

class ServerTrustPolicyExplorationBasicX509PolicyValidationTestCase: ServerTrustPolicyTestCase {
    func testThatAnchoredRootCertificatePassesBasicX509ValidationWithRootInTrust() {
        // Given
        let trust = TestTrusts.trustWithCertificates([
            TestCertificates.LeafDNSNameAndURI,
            TestCertificates.IntermediateCA1,
            TestCertificates.RootCA
        ])

        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateBasicX509()!]
        SecTrustSetPolicies(trust, policies)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should be valid")
    }

    func testThatAnchoredRootCertificatePassesBasicX509ValidationWithoutRootInTrust() {
        // Given
        let trust = TestTrusts.leafDNSNameAndURI.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateBasicX509()!]
        SecTrustSetPolicies(trust, policies)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should be valid")
    }

    func testThatCertificateMissingDNSNamePassesBasicX509Validation() {
        // Given
        let trust = TestTrusts.leafMissingDNSNameAndURI.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateBasicX509()!]
        SecTrustSetPolicies(trust, policies)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should be valid")
    }

    func testThatExpiredCertificateFailsBasicX509Validation() {
        // Given
        let trust = TestTrusts.leafExpired.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateBasicX509()!]
        SecTrustSetPolicies(trust, policies)

        // Then
        XCTAssertFalse(trustIsValid(trust), "trust should not be valid")
    }
}

// MARK: -

class ServerTrustPolicyExplorationSSLPolicyValidationTestCase: ServerTrustPolicyTestCase {
    func testThatAnchoredRootCertificatePassesSSLValidationWithRootInTrust() {
        // Given
        let trust = TestTrusts.trustWithCertificates([
            TestCertificates.LeafDNSNameAndURI,
            TestCertificates.IntermediateCA1,
            TestCertificates.RootCA
        ])

        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, "test.alamofire.org")!]
        SecTrustSetPolicies(trust, policies)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should be valid")
    }

    func testThatAnchoredRootCertificatePassesSSLValidationWithoutRootInTrust() {
        // Given
        let trust = TestTrusts.leafDNSNameAndURI.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, "test.alamofire.org")!]
        SecTrustSetPolicies(trust, policies)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should be valid")
    }

    func testThatCertificateMissingDNSNameFailsSSLValidation() {
        // Given
        let trust = TestTrusts.leafMissingDNSNameAndURI.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, "test.alamofire.org")!]
        SecTrustSetPolicies(trust, policies)

        // Then
        XCTAssertFalse(trustIsValid(trust), "trust should not be valid")
    }

    func testThatWildcardCertificatePassesSSLValidation() {
        // Given
        let trust = TestTrusts.leafWildcard.trust // *.alamofire.org
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, "test.alamofire.org")!]
        SecTrustSetPolicies(trust, policies)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should be valid")
    }

    func testThatDNSNameCertificatePassesSSLValidation() {
        // Given
        let trust = TestTrusts.leafValidDNSName.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, "test.alamofire.org")!]
        SecTrustSetPolicies(trust, policies)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should be valid")
    }

    func testThatURICertificateFailsSSLValidation() {
        // Given
        let trust = TestTrusts.leafValidURI.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, "test.alamofire.org")!]
        SecTrustSetPolicies(trust, policies)

        // Then
        XCTAssertFalse(trustIsValid(trust), "trust should not be valid")
    }

    func testThatMultipleDNSNamesCertificatePassesSSLValidationForAllEntries() {
        // Given
        let trust = TestTrusts.leafMultipleDNSNames.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [
            SecPolicyCreateSSL(true, "test.alamofire.org")!,
            SecPolicyCreateSSL(true, "blog.alamofire.org")!,
            SecPolicyCreateSSL(true, "www.alamofire.org")!
        ]
        SecTrustSetPolicies(trust, policies)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should not be valid")
    }

    func testThatPassingNilForHostParameterAllowsCertificateMissingDNSNameToPassSSLValidation() {
        // Given
        let trust = TestTrusts.leafMissingDNSNameAndURI.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, nil)!]
        SecTrustSetPolicies(trust, policies)

        // Then
        XCTAssertTrue(trustIsValid(trust), "trust should not be valid")
    }

    func testThatExpiredCertificateFailsSSLValidation() {
        // Given
        let trust = TestTrusts.leafExpired.trust
        setRootCertificateAsLoneAnchorCertificateForTrust(trust)

        // When
        let policies = [SecPolicyCreateSSL(true, "test.alamofire.org")!]
        SecTrustSetPolicies(trust, policies)

        // Then
        XCTAssertFalse(trustIsValid(trust), "trust should not be valid")
    }
}

// MARK: - Server Trust Policy Tests -

class ServerTrustPolicyPerformDefaultEvaluationTestCase: ServerTrustPolicyTestCase {

    // MARK: Do NOT Validate Host

    func testThatValidCertificateChainPassesEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let serverTrustPolicy = ServerTrustPolicy.performDefaultEvaluation(validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatNonAnchoredRootCertificateChainFailsEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.trustWithCertificates([
            TestCertificates.LeafValidDNSName,
            TestCertificates.IntermediateCA2
        ])
        let serverTrustPolicy = ServerTrustPolicy.performDefaultEvaluation(validateHost: false)

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatMissingDNSNameLeafCertificatePassesEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafMissingDNSNameAndURI.trust
        let serverTrustPolicy = ServerTrustPolicy.performDefaultEvaluation(validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatExpiredCertificateChainFailsEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let serverTrustPolicy = ServerTrustPolicy.performDefaultEvaluation(validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatMissingIntermediateCertificateInChainFailsEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSNameMissingIntermediate.trust
        let serverTrustPolicy = ServerTrustPolicy.performDefaultEvaluation(validateHost: false)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    // MARK: Validate Host

    func testThatValidCertificateChainPassesEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let serverTrustPolicy = ServerTrustPolicy.performDefaultEvaluation(validateHost: true)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatNonAnchoredRootCertificateChainFailsEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.trustWithCertificates([
            TestCertificates.LeafValidDNSName,
            TestCertificates.IntermediateCA2
        ])
        let serverTrustPolicy = ServerTrustPolicy.performDefaultEvaluation(validateHost: true)

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatMissingDNSNameLeafCertificateFailsEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafMissingDNSNameAndURI.trust
        let serverTrustPolicy = ServerTrustPolicy.performDefaultEvaluation(validateHost: true)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatWildcardedLeafCertificateChainPassesEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafWildcard.trust
        let serverTrustPolicy = ServerTrustPolicy.performDefaultEvaluation(validateHost: true)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatExpiredCertificateChainFailsEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let serverTrustPolicy = ServerTrustPolicy.performDefaultEvaluation(validateHost: true)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatMissingIntermediateCertificateInChainFailsEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSNameMissingIntermediate.trust
        let serverTrustPolicy = ServerTrustPolicy.performDefaultEvaluation(validateHost: true)

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }
}

// MARK: -

class ServerTrustPolicyPinCertificatesTestCase: ServerTrustPolicyTestCase {

    // MARK: Validate Certificate Chain Without Validating Host

    func testThatPinnedLeafCertificatePassesEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.LeafValidDNSName]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinnedIntermediateCertificatePassesEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.IntermediateCA2]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinnedRootCertificatePassesEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.RootCA]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningLeafCertificateNotInCertificateChainFailsEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.LeafSignedByCA2]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningIntermediateCertificateNotInCertificateChainFailsEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.IntermediateCA1]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningExpiredLeafCertificateFailsEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let certificates = [TestCertificates.LeafExpired]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningIntermediateCertificateWithExpiredLeafCertificateFailsEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let certificates = [TestCertificates.IntermediateCA2]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    // MARK: Validate Certificate Chain and Host

    func testThatPinnedLeafCertificatePassesEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.LeafValidDNSName]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: true
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinnedIntermediateCertificatePassesEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.IntermediateCA2]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: true
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinnedRootCertificatePassesEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.RootCA]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: true
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningLeafCertificateNotInCertificateChainFailsEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.LeafSignedByCA2]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: true
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningIntermediateCertificateNotInCertificateChainFailsEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.IntermediateCA1]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: true
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningExpiredLeafCertificateFailsEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let certificates = [TestCertificates.LeafExpired]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: true
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningIntermediateCertificateWithExpiredLeafCertificateFailsEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let certificates = [TestCertificates.IntermediateCA2]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: true,
            validateHost: true
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    // MARK: Do NOT Validate Certificate Chain or Host

    func testThatPinnedLeafCertificateWithoutCertificateChainValidationPassesEvaluation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.LeafValidDNSName]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinnedIntermediateCertificateWithoutCertificateChainValidationPassesEvaluation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.IntermediateCA2]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinnedRootCertificateWithoutCertificateChainValidationPassesEvaluation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.RootCA]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningLeafCertificateNotInCertificateChainWithoutCertificateChainValidationFailsEvaluation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.LeafSignedByCA2]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningIntermediateCertificateNotInCertificateChainWithoutCertificateChainValidationFailsEvaluation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let certificates = [TestCertificates.IntermediateCA1]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningExpiredLeafCertificateWithoutCertificateChainValidationPassesEvaluation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let certificates = [TestCertificates.LeafExpired]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningIntermediateCertificateWithExpiredLeafCertificateWithoutCertificateChainValidationPassesEvaluation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let certificates = [TestCertificates.IntermediateCA2]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)
        
        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningRootCertificateWithExpiredLeafCertificateWithoutCertificateChainValidationPassesEvaluation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let certificates = [TestCertificates.RootCA]
        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningMultipleCertificatesWithoutCertificateChainValidationPassesEvaluation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust

        let certificates = [
            TestCertificates.LeafMultipleDNSNames, // not in certificate chain
            TestCertificates.LeafSignedByCA1,      // not in certificate chain
            TestCertificates.LeafExpired,          // in certificate chain 👍🏼👍🏼
            TestCertificates.LeafWildcard,         // not in certificate chain
            TestCertificates.LeafDNSNameAndURI,    // not in certificate chain
        ]

        let serverTrustPolicy = ServerTrustPolicy.pinCertificates(
            certificates: certificates,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }
}

// MARK: -

class ServerTrustPolicyPinPublicKeysTestCase: ServerTrustPolicyTestCase {

    // MARK: Validate Certificate Chain Without Validating Host

    func testThatPinningLeafKeyPassesEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.LeafValidDNSName]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: true,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningIntermediateKeyPassesEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.IntermediateCA2]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: true,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningRootKeyPassesEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.RootCA]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: true,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningKeyNotInCertificateChainFailsEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.LeafSignedByCA2]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: true,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningBackupKeyPassesEvaluationWithoutHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.LeafSignedByCA1, TestPublicKeys.IntermediateCA1, TestPublicKeys.LeafValidDNSName]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: true,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    // MARK: Validate Certificate Chain and Host

    func testThatPinningLeafKeyPassesEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.LeafValidDNSName]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: true,
            validateHost: true
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningIntermediateKeyPassesEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.IntermediateCA2]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: true,
            validateHost: true
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningRootKeyPassesEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.RootCA]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: true,
            validateHost: true
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningKeyNotInCertificateChainFailsEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.LeafSignedByCA2]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: true,
            validateHost: true
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningBackupKeyPassesEvaluationWithHostValidation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let publicKeys = [TestPublicKeys.LeafSignedByCA1, TestPublicKeys.IntermediateCA1, TestPublicKeys.LeafValidDNSName]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: true,
            validateHost: true
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    // MARK: Do NOT Validate Certificate Chain or Host

    func testThatPinningLeafKeyWithoutCertificateChainValidationPassesEvaluationWithMissingIntermediateCertificate() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSNameMissingIntermediate.trust
        let publicKeys = [TestPublicKeys.LeafValidDNSName]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningRootKeyWithoutCertificateChainValidationFailsEvaluationWithMissingIntermediateCertificate() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSNameMissingIntermediate.trust
        let publicKeys = [TestPublicKeys.RootCA]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }

    func testThatPinningLeafKeyWithoutCertificateChainValidationPassesEvaluationWithIncorrectIntermediateCertificate() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSNameWithIncorrectIntermediate.trust
        let publicKeys = [TestPublicKeys.LeafValidDNSName]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningLeafKeyWithoutCertificateChainValidationPassesEvaluationWithExpiredLeafCertificate() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let publicKeys = [TestPublicKeys.LeafExpired]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningIntermediateKeyWithoutCertificateChainValidationPassesEvaluationWithExpiredLeafCertificate() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let publicKeys = [TestPublicKeys.IntermediateCA2]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatPinningRootKeyWithoutCertificateChainValidationPassesEvaluationWithExpiredLeafCertificate() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let publicKeys = [TestPublicKeys.RootCA]
        let serverTrustPolicy = ServerTrustPolicy.pinPublicKeys(
            publicKeys: publicKeys,
            validateCertificateChain: false,
            validateHost: false
        )

        // When
        setRootCertificateAsLoneAnchorCertificateForTrust(serverTrust)
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }
}

// MARK: -

class ServerTrustPolicyDisableEvaluationTestCase: ServerTrustPolicyTestCase {
    func testThatCertificateChainMissingIntermediateCertificatePassesEvaluation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSNameMissingIntermediate.trust
        let serverTrustPolicy = ServerTrustPolicy.disableEvaluation

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatExpiredLeafCertificatePassesEvaluation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafExpired.trust
        let serverTrustPolicy = ServerTrustPolicy.disableEvaluation

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }
}

// MARK: -

class ServerTrustPolicyCustomEvaluationTestCase: ServerTrustPolicyTestCase {
    func testThatReturningTrueFromClosurePassesEvaluation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let serverTrustPolicy = ServerTrustPolicy.customEvaluation { _, _ in
            return true
        }

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation")
    }

    func testThatReturningFalseFromClosurePassesEvaluation() {
        // Given
        let host = "test.alamofire.org"
        let serverTrust = TestTrusts.leafValidDNSName.trust
        let serverTrustPolicy = ServerTrustPolicy.customEvaluation { _, _ in
            return false
        }

        // When
        let serverTrustIsValid = serverTrustPolicy.evaluateServerTrust(serverTrust, isValidForHost: host)

        // Then
        XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation")
    }
}

// MARK: -

class ServerTrustPolicyCertificatesInBundleTestCase: ServerTrustPolicyTestCase {
    func testOnlyValidCertificatesAreDetected() {
        // Given
        // Files present in bundle in the form of type+encoding+extension [key|cert][DER|PEM].[cer|crt|der|key|pem]
        // certDER.cer: DER-encoded well-formed certificate
        // certDER.crt: DER-encoded well-formed certificate
        // certDER.der: DER-encoded well-formed certificate
        // certPEM.*: PEM-encoded well-formed certificates, expected to fail: Apple API only handles DER encoding
        // devURandomGibberish.crt: Random data, should fail
        // keyDER.der: DER-encoded key, not a certificate, should fail

        // When
        let certificates = ServerTrustPolicy.certificatesInBundle(
            Bundle(for: ServerTrustPolicyCertificatesInBundleTestCase.self)
        )

        // Then
        // Expectation: 18 well-formed certificates in the test bundle plus 4 invalid certificates.
        #if os(OSX)
            // For some reason, OSX is allowing all certificates to be considered valid. Need to file a
            // rdar demonstrating this behavior.
            XCTAssertEqual(certificates.count, 22, "Expected 22 well-formed certificates")
        #else
            XCTAssertEqual(certificates.count, 18, "Expected 18 well-formed certificates")
        #endif
    }
}
