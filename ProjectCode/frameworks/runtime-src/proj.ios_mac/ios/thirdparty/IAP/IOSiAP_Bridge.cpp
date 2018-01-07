//==========================================================================================
// IOSiAP_Bridge.cpp
// Created by Dolphin Lee.
//==========================================================================================

#include "IOSiAP_Bridge.h"
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
//==========================================================================================
// 构造函数
//==========================================================================================

IOSiAP_Bridge::IOSiAP_Bridge()
{
    _quantity = 0;
    _identifier = "";
    _product = nullptr;
    _productCallback = nullptr;
    _productCallback = nullptr;
    
    iap = nullptr;
    // 创建IOSIAP
    
    iap = new IOSiAP();
    iap->delegate = this;
}

IOSiAP_Bridge::~IOSiAP_Bridge()
{
    delete iap;
}

//==========================================================================================
// 回调函数（IOSIAP返回结果）
//==========================================================================================

// ［回调］获取商品请求成功返回
void IOSiAP_Bridge::onRequestProductsFinish(void)
{
    // 必须在onRequestProductsFinish后才能去请求IAP产品数据
    _product = iap->iOSProductByIdentifier(_identifier);
    
    // 获取成功后即可发起付款请求
    // iap->paymentWithProduct(_product, _quantity);
    
    // 回调出去
    if (_productCallback)
    {
        _productCallback(_product, IAP_REQUEST_SUCCESS);
    }
}

// ［回调］获取商品请求失败返回
void IOSiAP_Bridge::onRequestProductsError(int code)
{
    // 这里requestProducts出错了，不能进行后面的所有操作
    
    // 回调出去
    if (_productCallback)
    {
        _productCallback(_product, code);
    }
}

// ［回调］支付结果返回
void IOSiAP_Bridge::onPaymentEvent(std::string &identifier, IOSiAPPaymentEvent event, int quantity)
{
    if (event == IOSIAP_PAYMENT_PURCHASING)
    {
        // 不需要做任何处理
    }
    else if (event == IOSIAP_PAYMENT_PURCHAED)
    {
        // 付款成功
        if (_paymentCallback)
        {
            _paymentCallback(true, identifier, quantity);
        }
    }
    else if (event == IOSIAP_PAYMENT_FAILED)
    {
        // 付款失败
        if (_paymentCallback)
        {
            _paymentCallback(false, identifier, quantity);
        }
    }
    else if (event == IOSIAP_PAYMENT_RESTORED)
    {
        // 恢复购买
        if (_restoreCallback)
        {
            _restoreCallback(identifier, quantity);
        }
    }
}

// ［回调］恢复购买完成回调
void IOSiAP_Bridge::onRestoreFinished(bool succeed)
{
    // 恢复购买完成
    if (_restoreFinishCallback)
    {
        _restoreFinishCallback(succeed);
    }
}

//==========================================================================================
// 外部调用
//==========================================================================================

// 获取商品信息
void IOSiAP_Bridge::requestProducts(std::string &identifier, iapProductCallback callback, const std::string &url, const int &dwUid)
{
    _identifier = identifier;
    _productCallback = callback;
    
    std::vector<std::string> vIdentifiers;
    vIdentifiers.push_back(_identifier);
    
    iap->m_strUrl = url;
    iap->m_dwUserID = dwUid;
    // 获取商品信息
    iap->requestProducts(vIdentifiers);
}

// 付款请求
void IOSiAP_Bridge::requestPayment(int quantity, float price, iapPaymentCallback callback)
{
    _quantity = quantity;
    _paymentCallback = callback;
    
    if (_product)
    {
        // 支付请求
        iap->paymentWithProduct(_product, price, _quantity);
    }
}

// ［请求］恢复购买
void IOSiAP_Bridge::requestRestore(iapRestoreCallback restoreCallback, iapRestoreFinishCallback finishCallback)
{
    _restoreCallback = restoreCallback;
    _restoreFinishCallback = finishCallback;
    
    // 恢复请求
    iap->restorePayment();
}
#endif
//==========================================================================================
//
//==========================================================================================

