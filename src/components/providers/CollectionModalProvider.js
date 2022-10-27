import { createContext, useState } from 'react'

const contextDefaultValues = {
  modalCollection: undefined,
  isModalOpen: false,
  setModalCollection: () => {},
  setIsModalOpen: () => {}
}

export const CollectionModalContext = createContext(
  contextDefaultValues
)

export default function CollectionModalProvider ({ children }) {
  const [modalCollection, setModalCollection] = useState(contextDefaultValues.modalCollection)
  const [isModalOpen, setIsModalOpen] = useState(contextDefaultValues.isModalOpen)

  return (
    <CollectionModalContext.Provider
      value={{
        modalCollection,
        isModalOpen,
        setModalCollection,
        setIsModalOpen
      }}
    >
      {children}
    </CollectionModalContext.Provider>
  )
};
