#ifndef __iAP_JSBinding__IOSiAP__
#define __iAP_JSBinding__IOSiAP__

#include <iostream>
#include <vector>

class IOSProduct
{
public:
    std::string productIdentifier;
    std::string localizedTitle;
    std::string localizedDescription;
    std::string localizedPrice;// has be localed, just display it on UI.
    bool isValid;
    int index;//internal use : index of skProducts
};

typedef enum {
    IOSIAP_PAYMENT_PURCHASING,// just notify, UI do nothing
    IOSIAP_PAYMENT_PURCHAED,// need unlock App Functionality
    IOSIAP_PAYMENT_FAILED,// remove waiting on UI, tall user payment was failed
    IOSIAP_PAYMENT_RESTORED,// need unlock App Functionality, consumble payment No need to care about this.
    IOSIAP_PAYMENT_REMOVED,// remove waiting on UI
} IOSiAPPaymentEvent;

class IOSiAPDelegate
{
public:
    virtual ~IOSiAPDelegate() {}
    // for request product
    virtual void onRequestProductsFinish(void) = 0;
    virtual void onRequestProductsError(int code) = 0;
    // for payment event (also for restore event)
    virtual void onPaymentEvent(std::string &identifier, IOSiAPPaymentEvent event, int quantity) = 0;
    // for restore finished
    virtual void onRestoreFinished(bool succeed) = 0;
};

class IOSiAP
{
public:
    IOSiAP();
    ~IOSiAP();
    void requestProducts(std::vector <std::string> &productIdentifiers); // 请求商品
    IOSProduct *iOSProductByIdentifier(std::string &identifier);
    void paymentWithProduct(IOSProduct *iosProduct, float price, int quantity = 1); // 请求支付
    void restorePayment(); // 恢复购买
    
    IOSiAPDelegate *delegate;
    // ===  internal use for object-c class ===
    void *skProducts;// object-c SKProduct
    void *skTransactionObserver;// object-c TransactionObserver
    std::vector<IOSProduct *> iOSProducts;
    int m_price;
    std::string m_strUrl;
    int m_dwUserID;
};

#endif /* defined(__iAP_JSBinding__IOSiAP__) */
