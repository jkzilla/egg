export interface Egg {
  id: string
  type: string
  price: number
  quantityAvailable: number
  description?: string
}

export interface PurchaseResult {
  success: boolean
  message: string
  remainingQuantity: number
}

export interface CartItem {
  egg: Egg
  quantity: number
}
