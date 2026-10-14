//
//  PreloadedSession.swift
//  KhoaAI
//
//  Created by Khoa Dev.
//  Bundled verified session for immediate out-of-the-box chat without manual configuration.
//

import Foundation

public struct PreloadedSession {
    public static let token = "3QFl9aZYGPrEGLkw1IIfrNIXvE+5Ec6jxQ6wzkU8mtQDPDZafYlQuaSQCm+03eAp"
    public static let userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36"
    public static let cookiesJson = """
{
  "aws-waf-token": "a0ed761f-2097-400b-8b57-2752b7bbc483:BgoAsgRawIwrBQAA:ljmUXy2+ZgnPfo3f34kuuyB1L/6uwqDXbT61f/PSR0gUZKkMykESDnZUqyGSV0Ephi04BWSZze4S/0WOLGKnVaWmcNx9vhnETLAn6F9NtvG1D4di/kFYQ6G76gCsVYnSBBKO1wXDs+fMBEFXTQEn8M5k5dsuw9TV6ImMl1dGUu5XCJQkhI++i37ACzbh0HpG5LTcjtjFH9LxrxVWzm386hXPEo0JwBlszww7RVGJSelbP1ZhX2562snnnUZfg6AvQm6wQ4elulddXrX7wk4vCEtZdVp2c3MuSKL1vaT0We0tSY7TteMlVT9WKFAdYK5mJmUbwlZELjuyhQ==",
  "smidV2": "202610142204288bc0f77749c91966a56f81ae966117c80099a8efb4cffd5d0",
  ".thumbcache_6b2e5483f9d858d7c661c5e276b6a6ae": "Lycw+WAxMMFKRQHaDbQpmkjc/C9zSKo2bUXvl9OiIhoubNo2Zvu5WWCXoMGG4jz+qoqkA9igI3OG1ePc1kzmaA%3D%3D",
  "__cf_bm": "yeg_p7Rhyk50KrM1qBBAQIYC99LrC.e09O1s4VFSnU8-1791995723.7491248-1.0.1.1-ATXjvxJ2pMO.iv_nRqqUTXmQtFt89GEWqNOYuba_UZmW7fk.IeOumpsLXw0.v5qNCF4TuZT5a4OcipUhm_7BKYTaAAcgPaz7DmIktARHmr.6oQwUOzF9neclSrV4uJmh",
  "hmt_id": "a2a0b006-6cec-458b-a743-76ec301919c0",
  "__cflb": "0H28vk2VKwPbLoawFiy2SpCmh7KAAR3bFrNd6BfZgjo",
  "OTZ": "8828196_28_28__28_",
  "NID": "Cu0BCAESnwEBOxGDSDviGr_xGobY5YiyKmQJAXXQZ2UcyrdlX46vQmV5nwzU9nd6Uxyu-ou-m_9vOxCTiGE7MSoo_Hgudx0w8dHAzjRngfdLuCRlmmUbxWPpl8bMjF-5a4KpHvCO-lJ6t8-Mmss0IjeqlGX5eVQuwyweb-qU3BADlAlpk5XBWa17hfFRvAI6W070B8UOs8AemINhbYz4y4A6RUY-zgEoATJFAdKsB8_5YP7QPJYSK9ba7VsqFPmgiL2oecSm2lwVjkWbKvucr7a_RJBuYAWHhI5NImAD-Xy1D7pe4hRNH_LD5CmyTs0M",
  "HSID": "A7pEp2DkZIQag8dzk",
  "SSID": "AJuqdETLDJmi3K_Sb",
  "APISID": "p8Qh_OZKnoX1cL_R/AwyC0EjnF5UHMVOyo",
  "SAPISID": "KZWxJRmNx3yVuAAx/AkYjoEWKwiMY4Vx5K",
  "__Secure-1PAPISID": "KZWxJRmNx3yVuAAx/AkYjoEWKwiMY4Vx5K",
  "__Secure-3PAPISID": "KZWxJRmNx3yVuAAx/AkYjoEWKwiMY4Vx5K",
  "ACCOUNT_CHOOSER": "AFx_qI4iYLdHfB_jasrOFRbZaFm1bJh2Wcj6nmixrQZ9pSwPZgjlUDmoIy6kWnQCbKtKfSQiKwFis3U7_IG97AOsa1S3UlMm250vxzzFl3oOseErPXQgyLYrtiUWc2d1dsYskGXTsQSx",
  "LSID": "s.VN|s.youtube:g.a000DgkPbfn8drafoCdW7xqLG9jomVciytm7qNKUYqlrvoslcq1FErld38G1hcz3kFcKqPv7RAACgYKATUSARYSFQHGX2MigtmIKO4qWhQIs8QmzPCYThoVAUF8yKrtDqgZGI4ErrjdvwEMEdzo0076",
  "__Host-1PLSID": "s.VN|s.youtube:g.a000DgkPbfn8drafoCdW7xqLG9jomVciytm7qNKUYqlrvoslcq1FPhQB2bmfYaLBuNRS2SOH3wACgYKASgSARYSFQHGX2MikMm2k6fhMDVqyoYkvJ5irxoVAUF8yKonUV9qIraUhUo29nyVYDgY0076",
  "__Host-3PLSID": "s.VN|s.youtube:g.a000DgkPbfn8drafoCdW7xqLG9jomVciytm7qNKUYqlrvoslcq1FdpARSv27cygcbR03yeVUzwACgYKARASARYSFQHGX2MitVBseIXyxF-uG2H2vX2dFxoVAUF8yKrfsvM7BaM4OqT_n0lu5jjc0076",
  "__Secure-1PSIDTS": "sidts-CjcBkldj_8ZTiD10mRSkKVk59ePR5kbADpIhkTSm8kuMQcfsf061CbYLI1Dtb1feNWXPYbKg5bJGEAA",
  "__Secure-3PSIDTS": "sidts-CjcBkldj_8ZTiD10mRSkKVk59ePR5kbADpIhkTSm8kuMQcfsf061CbYLI1Dtb1feNWXPYbKg5bJGEAA",
  "SID": "g.a000DgkPbe_7xd6Bb4UKkmM-n35PeLqYcBJ7E28yhWAWsld7V1DGumULLzwYJ8xfV7Kuym-BvwACgYKAdsSARYSFQHGX2MiRrNOCLckvIBI6QwmGQ6LPRoVAUF8yKq-rXJaTMLRjq-T0R5RlJvp0076",
  "__Secure-1PSID": "g.a000DgkPbe_7xd6Bb4UKkmM-n35PeLqYcBJ7E28yhWAWsld7V1DGrFKWVNy0NdroIwsUvucp3wACgYKAYESARYSFQHGX2Mi7_WvhCf1ldV21gjlz7Kx0xoVAUF8yKp0p458YLrFnoyWyuGewM7p0076",
  "__Secure-3PSID": "g.a000DgkPbe_7xd6Bb4UKkmM-n35PeLqYcBJ7E28yhWAWsld7V1DGYcMzBdh9ekbg-x78kYmRlgACgYKAWcSARYSFQHGX2Mi8mepdDlyfoEIR4jojA_YwhoVAUF8yKr7ylL9k3c0Q-N5za_2w2U50076",
  "__Secure-1PSIDRTS": "sidts-CjcBkldj_8ZTiD10mRSkKVk59ePR5kbADpIhkTSm8kuMQcfsf061CbYLI1Dtb1feNWXPYbKg5bJGEAA",
  "__Secure-3PSIDRTS": "sidts-CjcBkldj_8ZTiD10mRSkKVk59ePR5kbADpIhkTSm8kuMQcfsf061CbYLI1Dtb1feNWXPYbKg5bJGEAA",
  "__Host-GAPS": "1:R8rkGH_DTEHvpHNG8L1EwOdyBd9XMIXAvIdaxFUmqn_LyEQrxJ2bTToh78kbduGtFnlcApU_lhQAjEyKg8k_yMI5xY2QynnDrlxyo3K54oCUyTh26C9bL-9nhiJycjk2Dlb_cHY41gTCIQ9WiX16YKxJbA_2oQNHdm-8OqhLJsvHWzIzunzIrQ:NHDGx9PkBGtxQi-L",
  "__Host-GAPSTS": "gapsts-Ci0BxkkdjUTfjizS3LVFM9gN0mw77-LBSCYb813Bflm5R6Ma0G_wtMH73BbH_tYQAQ==",
  "ds_session_id": "dced270131154e58b9c29d0e2d696e90",
  "SIDCC": "AKEyXzV-TYsq5WAy9oF1s9_KNb1R3mbHFURB_0TsIEq-kVY_n2FtyNmG_BAUIBecUYcwDZSr",
  "__Secure-1PSIDCC": "AKEyXzXVs0oL5f4o-ZKF2zVS5WHU6nc3dCgFiedf0SPcBD5EQQuZfaI6RiX8s3Y4eYduuBE5KQ",
  "__Secure-3PSIDCC": "AKEyXzUWIiNWWAsEDdL-vUxtp681raF_mSxRlr1lOcG4H6fsDcmyRc-UGSZiBliHP6zgRqG_"
}
"""

    public static var cookies: [String: String] {
        guard let data = cookiesJson.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        return dict
    }
}
