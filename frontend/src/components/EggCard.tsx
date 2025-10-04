import { useState } from 'react'
import { Egg } from '../types'
import { Plus, Minus } from 'lucide-react'

interface EggCardProps {
  egg: Egg
  onAddToCart: (egg: Egg, quantity: number) => void
}

export default function EggCard({ egg, onAddToCart }: EggCardProps) {
  const [quantity, setQuantity] = useState(1)

  const handleAddToCart = () => {
    if (quantity > 0 && quantity <= egg.quantityAvailable) {
      onAddToCart(egg, quantity)
      setQuantity(1)
    }
  }

  const incrementQuantity = () => {
    if (quantity < egg.quantityAvailable) {
      setQuantity(quantity + 1)
    }
  }

  const decrementQuantity = () => {
    if (quantity > 1) {
      setQuantity(quantity - 1)
    }
  }

  return (
    <div className="bg-white rounded-lg shadow-lg overflow-hidden hover:shadow-xl transition-shadow">
      <div className="bg-gradient-to-br from-amber-100 to-orange-200 h-48 flex items-center justify-center">
        <div className="text-8xl">🥚</div>
      </div>

      <div className="p-6">
        <h3 className="text-xl font-bold text-gray-800 mb-2">{egg.type}</h3>

        {egg.description && (
          <p className="text-gray-600 text-sm mb-4">{egg.description}</p>
        )}

        <div className="flex items-center justify-between mb-4">
          <span className="text-2xl font-bold text-amber-600">
            ${egg.price.toFixed(2)}
          </span>
          <span className="text-sm text-gray-500">
            {egg.quantityAvailable} available
          </span>
        </div>

        {egg.quantityAvailable > 0 ? (
          <>
            <div className="flex items-center gap-2 mb-4">
              <button
                onClick={decrementQuantity}
                className="bg-gray-200 hover:bg-gray-300 text-gray-700 p-2 rounded-lg transition-colors"
                disabled={quantity <= 1}
              >
                <Minus className="w-4 h-4" />
              </button>

              <input
                type="number"
                min="1"
                max={egg.quantityAvailable}
                value={quantity}
                onChange={(e) => {
                  const val = parseInt(e.target.value) || 1
                  setQuantity(Math.min(Math.max(1, val), egg.quantityAvailable))
                }}
                className="w-16 text-center border border-gray-300 rounded-lg py-2"
              />

              <button
                onClick={incrementQuantity}
                className="bg-gray-200 hover:bg-gray-300 text-gray-700 p-2 rounded-lg transition-colors"
                disabled={quantity >= egg.quantityAvailable}
              >
                <Plus className="w-4 h-4" />
              </button>
            </div>

            <button
              onClick={handleAddToCart}
              className="w-full bg-amber-600 hover:bg-amber-700 text-white font-semibold py-3 px-4 rounded-lg transition-colors"
            >
              Add to Cart
            </button>
          </>
        ) : (
          <div className="text-center text-red-600 font-semibold py-3">
            Out of Stock
          </div>
        )}
      </div>
    </div>
  )
}
