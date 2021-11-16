/* sane - Scanner Access Now Easy.

   Copyright (C) 2019 Povilas Kanapickas <povilas@radix.lt>

   This file is part of the SANE package.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#define DEBUG_DECLARE_ONLY

import tests
import minigtest
import tests_printers

import ../../../backend/genesys/low
import ../../../backend/genesys/enums

namespace genesys {

void test_create_slope_table_small_full_step()
{
    unsigned max_table_size = 1024;

    // created approximately from LIDE 110 slow table: { 62464, 7896, 2632, 0 }
    MotorSlope slope;
    slope.initial_speed_w = 62464;
    slope.max_speed_w = 2632;
    slope.acceleration = 1.2e-8;

    auto table = create_slope_table_for_speed(slope, 5000, StepType::FULL, 4, 8, max_table_size);

    std::vector<std::uint16_t> expected_table = {
        62464, 62464, 6420, 5000, 5000, 5000, 5000, 5000
    ]
    ASSERT_EQ(table.table, expected_table);
    ASSERT_EQ(table.table.size(), 8u);
    ASSERT_EQ(table.pixeltime_sum(), 156348u);


    table = create_slope_table_for_speed(slope, 3000, StepType::FULL, 4, 8, max_table_size);

    expected_table = {
        62464, 62464, 6420, 4552, 3720, 3223, 3000, 3000
    ]
    ASSERT_EQ(table.table, expected_table);
    ASSERT_EQ(table.table.size(), 8u);
    ASSERT_EQ(table.pixeltime_sum(), 148843u);
}

void test_create_slope_table_small_full_step_target_speed_too_high()
{
    unsigned max_table_size = 1024;

    // created approximately from LIDE 110 slow table: { 62464, 7896, 2632, 0 }
    MotorSlope slope;
    slope.initial_speed_w = 62464;
    slope.max_speed_w = 2632;
    slope.acceleration = 1.2e-8;

    auto table = create_slope_table_for_speed(slope, 2000, StepType::FULL, 4, 8, max_table_size);

    std::vector<std::uint16_t> expected_table = {
        62464, 62464, 6420, 4552, 3720, 3223, 2883, 2632
    ]
    ASSERT_EQ(table.table, expected_table);
    ASSERT_EQ(table.table.size(), 8u);
    ASSERT_EQ(table.pixeltime_sum(), 148358u);
}

void test_create_slope_table_small_half_step()
{
    unsigned max_table_size = 1024;

    // created approximately from LIDE 110 slow table: { 62464, 7896, 2632, 0 }
    MotorSlope slope;
    slope.initial_speed_w = 62464;
    slope.max_speed_w = 2632;
    slope.acceleration = 1.2e-8;

    auto table = create_slope_table_for_speed(slope, 5000, StepType::HALF, 4, 8, max_table_size);

    std::vector<std::uint16_t> expected_table = {
        31232, 31232, 3210, 2500, 2500, 2500, 2500, 2500
    ]
    ASSERT_EQ(table.table, expected_table);
    ASSERT_EQ(table.table.size(), 8u);
    ASSERT_EQ(table.pixeltime_sum(), 78174u);


    table = create_slope_table_for_speed(slope, 3000, StepType::HALF, 4, 8, max_table_size);

    expected_table = {
        31232, 31232, 3210, 2276, 1860, 1611, 1500, 1500
    ]
    ASSERT_EQ(table.table, expected_table);
    ASSERT_EQ(table.table.size(), 8u);
    ASSERT_EQ(table.pixeltime_sum(), 74421u);
}

void test_create_slope_table_large_full_step()
{
    unsigned max_table_size = 1024;

    /* created approximately from Canon 8600F table:
    54612, 54612, 34604, 26280, 21708, 18688, 16564, 14936, 13652, 12616,
    11768, 11024, 10400, 9872, 9392, 8960, 8584, 8240, 7940, 7648,
    7404, 7160, 6948, 6732, 6544, 6376, 6208, 6056, 5912, 5776,
    5644, 5520, 5408, 5292, 5192, 5092, 5000, 4908, 4820, 4736,
    4660, 4580, 4508, 4440, 4368, 4304, 4240, 4184, 4124, 4068,
    4012, 3960, 3908, 3860, 3808, 3764, 3720, 3676, 3636, 3592,
    3552, 3516, 3476, 3440, 3400, 3368, 3332, 3300, 3268, 3236,
    3204, 3176, 3148, 3116, 3088, 3060, 3036, 3008, 2984, 2956,
    2932, 2908, 2884, 2860, 2836, 2816, 2796, 2772, 2752, 2732,
    2708, 2692, 2672, 2652, 2632, 2616, 2596, 2576, 2560, 2544,
    2528, 2508, 2492, 2476, 2460, 2444, 2432, 2416, 2400, 2384,
    2372, 2356, 2344, 2328, 2316, 2304, 2288, 2276, 2260, 2252,
    2236, 2224, 2212, 2200, 2188, 2176, 2164, 2156, 2144, 2132,
    2120, 2108, 2100, 2088, 2080, 2068, 2056, 2048, 2036, 2028,
    2020, 2008, 2000, 1988, 1980, 1972, 1964, 1952, 1944, 1936,
    1928, 1920, 1912, 1900, 1892, 1884, 1876, 1868, 1860, 1856,
    1848, 1840, 1832, 1824, 1816, 1808, 1800, 1796, 1788, 1780,
    1772, 1764, 1760, 1752, 1744, 1740, 1732, 1724, 1720, 1712,
    1708, 1700, 1692, 1688, 1680, 1676, 1668, 1664, 1656, 1652,
    1644, 1640, 1636, 1628, 1624, 1616, 1612, 1608, 1600, 1596,
    1592, 1584, 1580, 1576, 1568, 1564, 1560, 1556, 1548, 1544,
    1540, 1536, 1528, 1524, 1520, 1516, 1512, 1508, 1500,
    */
    MotorSlope slope;
    slope.initial_speed_w = 54612;
    slope.max_speed_w = 1500;
    slope.acceleration = 1.013948e-9;

    auto table = create_slope_table_for_speed(slope, 3000, StepType::FULL, 4, 8, max_table_size);

    std::vector<std::uint16_t> expected_table = {
        54612, 54612, 20570, 15090, 12481, 10880, 9770, 8943, 8295, 7771,
        7335, 6964, 6645, 6366, 6120, 5900, 5702, 5523, 5359, 5210,
        5072, 4945, 4826, 4716, 4613, 4517, 4426, 4341, 4260, 4184,
        4111, 4043, 3977, 3915, 3855, 3799, 3744, 3692, 3642, 3594,
        3548, 3503, 3461, 3419, 3379, 3341, 3304, 3268, 3233, 3199,
        3166, 3135, 3104, 3074, 3045, 3017, 3000, 3000, 3000, 3000,
    ]
    ASSERT_EQ(table.table, expected_table);
    ASSERT_EQ(table.table.size(), 60u);
    ASSERT_EQ(table.pixeltime_sum(), 412616u);


    table = create_slope_table_for_speed(slope, 1500, StepType::FULL, 4, 8, max_table_size);

    expected_table = {
        54612, 54612, 20570, 15090, 12481, 10880, 9770, 8943, 8295, 7771,
        7335, 6964, 6645, 6366, 6120, 5900, 5702, 5523, 5359, 5210,
        5072, 4945, 4826, 4716, 4613, 4517, 4426, 4341, 4260, 4184,
        4111, 4043, 3977, 3915, 3855, 3799, 3744, 3692, 3642, 3594,
        3548, 3503, 3461, 3419, 3379, 3341, 3304, 3268, 3233, 3199,
        3166, 3135, 3104, 3074, 3045, 3017, 2989, 2963, 2937, 2911,
        2886, 2862, 2839, 2816, 2794, 2772, 2750, 2729, 2709, 2689,
        2670, 2651, 2632, 2614, 2596, 2578, 2561, 2544, 2527, 2511,
        2495, 2480, 2464, 2449, 2435, 2420, 2406, 2392, 2378, 2364,
        2351, 2338, 2325, 2313, 2300, 2288, 2276, 2264, 2252, 2241,
        2229, 2218, 2207, 2196, 2186, 2175, 2165, 2155, 2145, 2135,
        2125, 2115, 2106, 2096, 2087, 2078, 2069, 2060, 2051, 2042,
        2034, 2025, 2017, 2009, 2000, 1992, 1984, 1977, 1969, 1961,
        1953, 1946, 1938, 1931, 1924, 1917, 1910, 1903, 1896, 1889,
        1882, 1875, 1869, 1862, 1855, 1849, 1843, 1836, 1830, 1824,
        1818, 1812, 1806, 1800, 1794, 1788, 1782, 1776, 1771, 1765,
        1760, 1754, 1749, 1743, 1738, 1733, 1727, 1722, 1717, 1712,
        1707, 1702, 1697, 1692, 1687, 1682, 1677, 1673, 1668, 1663,
        1659, 1654, 1649, 1645, 1640, 1636, 1631, 1627, 1623, 1618,
        1614, 1610, 1606, 1601, 1597, 1593, 1589, 1585, 1581, 1577,
        1573, 1569, 1565, 1561, 1557, 1554, 1550, 1546, 1542, 1539,
        1535, 1531, 1528, 1524, 1520, 1517, 1513, 1510, 1506, 1503,
        1500, 1500, 1500, 1500,
    ]
    ASSERT_EQ(table.table, expected_table);
    ASSERT_EQ(table.table.size(), 224u);
    ASSERT_EQ(table.pixeltime_sum(), 734910u);
}

void test_create_slope_table_large_half_step()
{
    unsigned max_table_size = 1024;

    // created approximately from Canon 8600F table, see the full step test for the data

    MotorSlope slope;
    slope.initial_speed_w = 54612;
    slope.max_speed_w = 1500;
    slope.acceleration = 1.013948e-9;

    auto table = create_slope_table_for_speed(slope, 3000, StepType::HALF, 4, 8, max_table_size);

    std::vector<std::uint16_t> expected_table = {
        27306, 27306, 10285, 7545, 6240, 5440, 4885, 4471, 4147, 3885,
        3667, 3482, 3322, 3183, 3060, 2950, 2851, 2761, 2679, 2605,
        2536, 2472, 2413, 2358, 2306, 2258, 2213, 2170, 2130, 2092,
        2055, 2021, 1988, 1957, 1927, 1899, 1872, 1846, 1821, 1797,
        1774, 1751, 1730, 1709, 1689, 1670, 1652, 1634, 1616, 1599,
        1583, 1567, 1552, 1537, 1522, 1508, 1500, 1500, 1500, 1500,
    ]
    ASSERT_EQ(table.table, expected_table);
    ASSERT_EQ(table.table.size(), 60u);
    ASSERT_EQ(table.pixeltime_sum(), 206294u);


    table = create_slope_table_for_speed(slope, 1500, StepType::HALF, 4, 8, max_table_size);

    expected_table = {
        27306, 27306, 10285, 7545, 6240, 5440, 4885, 4471, 4147, 3885,
        3667, 3482, 3322, 3183, 3060, 2950, 2851, 2761, 2679, 2605,
        2536, 2472, 2413, 2358, 2306, 2258, 2213, 2170, 2130, 2092,
        2055, 2021, 1988, 1957, 1927, 1899, 1872, 1846, 1821, 1797,
        1774, 1751, 1730, 1709, 1689, 1670, 1652, 1634, 1616, 1599,
        1583, 1567, 1552, 1537, 1522, 1508, 1494, 1481, 1468, 1455,
        1443, 1431, 1419, 1408, 1397, 1386, 1375, 1364, 1354, 1344,
        1335, 1325, 1316, 1307, 1298, 1289, 1280, 1272, 1263, 1255,
        1247, 1240, 1232, 1224, 1217, 1210, 1203, 1196, 1189, 1182,
        1175, 1169, 1162, 1156, 1150, 1144, 1138, 1132, 1126, 1120,
        1114, 1109, 1103, 1098, 1093, 1087, 1082, 1077, 1072, 1067,
        1062, 1057, 1053, 1048, 1043, 1039, 1034, 1030, 1025, 1021,
        1017, 1012, 1008, 1004, 1000, 996, 992, 988, 984, 980,
        976, 973, 969, 965, 962, 958, 955, 951, 948, 944,
        941, 937, 934, 931, 927, 924, 921, 918, 915, 912,
        909, 906, 903, 900, 897, 894, 891, 888, 885, 882,
        880, 877, 874, 871, 869, 866, 863, 861, 858, 856,
        853, 851, 848, 846, 843, 841, 838, 836, 834, 831,
        829, 827, 824, 822, 820, 818, 815, 813, 811, 809,
        807, 805, 803, 800, 798, 796, 794, 792, 790, 788,
        786, 784, 782, 780, 778, 777, 775, 773, 771, 769,
        767, 765, 764, 762, 760, 758, 756, 755, 753, 751,
        750, 750, 750, 750,
    ]
    ASSERT_EQ(table.table, expected_table);
    ASSERT_EQ(table.table.size(), 224u);
    ASSERT_EQ(table.pixeltime_sum(), 367399u);
}

void test_motor()
{
    test_create_slope_table_small_full_step();
    test_create_slope_table_small_full_step_target_speed_too_high();
    test_create_slope_table_small_half_step();
    test_create_slope_table_large_full_step();
    test_create_slope_table_large_half_step();
}

} // namespace genesys
