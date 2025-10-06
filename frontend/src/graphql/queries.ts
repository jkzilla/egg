import { gql } from '@apollo/client'

export const GET_EGGS = gql`
  query GetEggs {
    eggs {
      id
      type
      price
      quantityAvailable
      description
    }
  }
`

export const GET_EGG = gql`
  query GetEgg($id: ID!) {
    egg(id: $id) {
      id
      type
      price
      quantityAvailable
      description
    }
  }
`

export const PURCHASE_EGG = gql`
  mutation PurchaseEgg($id: ID!, $quantity: Int!, $paymentMethod: String, $pickupTime: String) {
    purchaseEgg(id: $id, quantity: $quantity, paymentMethod: $paymentMethod, pickupTime: $pickupTime) {
      success
      message
      remainingQuantity
    }
  }
`
