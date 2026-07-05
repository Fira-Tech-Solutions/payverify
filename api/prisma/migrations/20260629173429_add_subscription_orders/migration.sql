-- CreateTable
CREATE TABLE "SubscriptionOrder" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "outTradeNo" TEXT NOT NULL,
    "tradeNo" TEXT,
    "tier" TEXT NOT NULL,
    "periodMonths" INTEGER NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "toPayUrl" TEXT,
    "paidAt" TIMESTAMP(3),
    "notifyPayload" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SubscriptionOrder_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "SubscriptionOrder_outTradeNo_key" ON "SubscriptionOrder"("outTradeNo");

-- CreateIndex
CREATE INDEX "SubscriptionOrder_businessId_idx" ON "SubscriptionOrder"("businessId");

-- CreateIndex
CREATE INDEX "SubscriptionOrder_outTradeNo_idx" ON "SubscriptionOrder"("outTradeNo");

-- AddForeignKey
ALTER TABLE "SubscriptionOrder" ADD CONSTRAINT "SubscriptionOrder_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "Business"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
