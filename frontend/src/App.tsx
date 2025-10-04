import { useState } from 'react'
import { useQuery } from '@apollo/client'
import { GET_EGGS } from './graphql/queries'
import { Egg, CartItem } from './types'
import EggCard from './components/EggCard'
import ShoppingCart from './components/ShoppingCart'
import Header from './components/Header'
import { ShoppingCart as CartIcon } from 'lucide-react'

function App() {
  const { loading, error, data, refetch } = useQuery(GET_EGGS)
  const [cart, setCart] = useState<CartItem[]>([])
  const [showCart, setShowCart] = useState(false)

  const addToCart = (egg: Egg, quantity: number) => {
    setCart((prevCart) => {
      const existingItem = prevCart.find((item) => item.egg.id === egg.id)
      if (existingItem) {
        return prevCart.map((item) =>
          item.egg.id === egg.id
            ? { ...item, quantity: item.quantity + quantity }
            : item
        )
      }
      return [...prevCart, { egg, quantity }]
    })
  }

  const removeFromCart = (eggId: string) => {
    setCart((prevCart) => prevCart.filter((item) => item.egg.id !== eggId))
  }

  const updateCartQuantity = (eggId: string, quantity: number) => {
    if (quantity <= 0) {
      removeFromCart(eggId)
      return
    }
    setCart((prevCart) =>
      prevCart.map((item) =>
        item.egg.id === eggId ? { ...item, quantity } : item
      )
    )
  }

  const clearCart = () => {
    setCart([])
  }

  const cartItemCount = cart.reduce((sum, item) => sum + item.quantity, 0)

  if (loading)
    return (
      <div className="min-h-screen bg-gradient-to-br from-amber-50 to-orange-100 flex items-center justify-center">
        <div className="text-2xl text-amber-800">Loading fresh eggs...</div>
      </div>
    )

  if (error)
    return (
      <div className="min-h-screen bg-gradient-to-br from-amber-50 to-orange-100 flex items-center justify-center">
        <div className="text-2xl text-red-600">Error: {error.message}</div>
      </div>
    )

  return (
    <div className="min-h-screen bg-gradient-to-br from-amber-50 to-orange-100">
      <Header />
      
      {/* Cart Button */}
      <button
        onClick={() => setShowCart(!showCart)}
        className="fixed top-6 right-6 bg-amber-600 text-white p-4 rounded-full shadow-lg hover:bg-amber-700 transition-colors z-50"
      >
        <CartIcon className="w-6 h-6" />
        {cartItemCount > 0 && (
          <span className="absolute -top-2 -right-2 bg-red-500 text-white text-xs font-bold rounded-full w-6 h-6 flex items-center justify-center">
            {cartItemCount}
          </span>
        )}
      </button>

      {/* Shopping Cart Sidebar */}
      <ShoppingCart
        cart={cart}
        isOpen={showCart}
        onClose={() => setShowCart(false)}
        onUpdateQuantity={updateCartQuantity}
        onRemove={removeFromCart}
        onClear={clearCart}
        onPurchaseComplete={refetch}
      />

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {data.eggs.map((egg: Egg) => (
            <EggCard key={egg.id} egg={egg} onAddToCart={addToCart} />
          ))}
        </div>
      </main>
    </div>
  )
}

export default App
