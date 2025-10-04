import { useState } from 'react'
import { useMutation } from '@apollo/client'
import { PURCHASE_EGG } from '../graphql/queries'
import { CartItem } from '../types'
import { X, Trash2, ShoppingBag } from 'lucide-react'

interface ShoppingCartProps {
  cart: CartItem[]
  isOpen: boolean
  onClose: () => void
  onUpdateQuantity: (eggId: string, quantity: number) => void
  onRemove: (eggId: string) => void
  onClear: () => void
  onPurchaseComplete: () => void
}

export default function ShoppingCart({
  cart,
  isOpen,
  onClose,
  onUpdateQuantity,
  onRemove,
  onClear,
  onPurchaseComplete,
}: ShoppingCartProps) {
  const [purchaseEgg] = useMutation(PURCHASE_EGG)
  const [purchasing, setPurchasing] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  const totalPrice = cart.reduce(
    (sum, item) => sum + item.egg.price * item.quantity,
    0
  )

  const handleCheckout = async () => {
    setPurchasing(true)
    setMessage(null)

    try {
      const results = await Promise.all(
        cart.map((item) =>
          purchaseEgg({
            variables: {
              id: item.egg.id,
              quantity: item.quantity,
            },
          })
        )
      )

      const allSuccessful = results.every(
        (result) => result.data?.purchaseEgg.success
      )

      if (allSuccessful) {
        setMessage({
          type: 'success',
          text: 'Purchase successful! Thank you for your order.',
        })
        onClear()
        onPurchaseComplete()
        setTimeout(() => {
          setMessage(null)
          onClose()
        }, 2000)
      } else {
        const failedItems = results
          .filter((result) => !result.data?.purchaseEgg.success)
          .map((result) => result.data?.purchaseEgg.message)
          .join(', ')
        setMessage({
          type: 'error',
          text: `Some items failed: ${failedItems}`,
        })
        onPurchaseComplete()
      }
    } catch (error) {
      setMessage({
        type: 'error',
        text: `Error: ${error instanceof Error ? error.message : 'Unknown error'}`,
      })
    } finally {
      setPurchasing(false)
    }
  }

  if (!isOpen) return null

  return (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black bg-opacity-50 z-40"
        onClick={onClose}
      />

      {/* Cart Sidebar */}
      <div className="fixed right-0 top-0 h-full w-full max-w-md bg-white shadow-2xl z-50 flex flex-col">
        {/* Header */}
        <div className="bg-amber-600 text-white p-6 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <ShoppingBag className="w-6 h-6" />
            <h2 className="text-2xl font-bold">Shopping Cart</h2>
          </div>
          <button
            onClick={onClose}
            className="hover:bg-amber-700 p-2 rounded-full transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Message */}
        {message && (
          <div
            className={`p-4 ${
              message.type === 'success'
                ? 'bg-green-100 text-green-800'
                : 'bg-red-100 text-red-800'
            }`}
          >
            {message.text}
          </div>
        )}

        {/* Cart Items */}
        <div className="flex-1 overflow-y-auto p-6">
          {cart.length === 0 ? (
            <div className="text-center text-gray-500 mt-8">
              <ShoppingBag className="w-16 h-16 mx-auto mb-4 opacity-50" />
              <p>Your cart is empty</p>
            </div>
          ) : (
            <div className="space-y-4">
              {cart.map((item) => (
                <div
                  key={item.egg.id}
                  className="bg-gray-50 rounded-lg p-4 flex items-center gap-4"
                >
                  <div className="text-4xl">🥚</div>

                  <div className="flex-1">
                    <h3 className="font-semibold text-gray-800">
                      {item.egg.type}
                    </h3>
                    <p className="text-sm text-gray-600">
                      ${item.egg.price.toFixed(2)} each
                    </p>

                    <div className="flex items-center gap-2 mt-2">
                      <input
                        type="number"
                        min="1"
                        max={item.egg.quantityAvailable}
                        value={item.quantity}
                        onChange={(e) => {
                          const val = parseInt(e.target.value) || 1
                          onUpdateQuantity(
                            item.egg.id,
                            Math.min(Math.max(1, val), item.egg.quantityAvailable)
                          )
                        }}
                        className="w-16 text-center border border-gray-300 rounded py-1"
                      />
                      <span className="text-sm text-gray-600">
                        × ${item.egg.price.toFixed(2)} = $
                        {(item.egg.price * item.quantity).toFixed(2)}
                      </span>
                    </div>
                  </div>

                  <button
                    onClick={() => onRemove(item.egg.id)}
                    className="text-red-500 hover:text-red-700 p-2"
                  >
                    <Trash2 className="w-5 h-5" />
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Footer */}
        {cart.length > 0 && (
          <div className="border-t border-gray-200 p-6 space-y-4">
            <div className="flex items-center justify-between text-xl font-bold">
              <span>Total:</span>
              <span className="text-amber-600">${totalPrice.toFixed(2)}</span>
            </div>

            <button
              onClick={handleCheckout}
              disabled={purchasing}
              className="w-full bg-amber-600 hover:bg-amber-700 disabled:bg-gray-400 text-white font-semibold py-3 px-4 rounded-lg transition-colors"
            >
              {purchasing ? 'Processing...' : 'Checkout'}
            </button>

            <button
              onClick={onClear}
              className="w-full bg-gray-200 hover:bg-gray-300 text-gray-700 font-semibold py-2 px-4 rounded-lg transition-colors"
            >
              Clear Cart
            </button>
          </div>
        )}
      </div>
    </>
  )
}
