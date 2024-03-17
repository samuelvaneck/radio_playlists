import * as React from 'react'
import Tab from './Tab'
import { useState } from "react";

function TabGroup() {
    const tabs = [["Songs", "/songs"], ["Artists", "/artists"], ["Radio stations", "/playlists"]]
    const [selectedTab, setSelectedTab] = useState(0)

    const handleTabClick = (tab) => {
        setSelectedTab(tab)
    }

    return (
        <div
            className="text-sm font-medium text-center text-gray-500 border-b border-gray-200 dark:text-gray-400 dark:border-gray-700">
            <ul className="flex -mb-px">
                {tabs.map((tab, index) => {
                    return <Tab key={tab}
                                name={tab[0]}
                                searchPath={tab[1]}
                                tabIndex={index}
                                activeTab={selectedTab}
                                onTabClick={handleTabClick} />
                })}
            </ul>
        </div>
    )
}

export default TabGroup
